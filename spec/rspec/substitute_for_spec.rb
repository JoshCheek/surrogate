require 'spec_helper'

describe 'substitute_for' do
  context 'exact substitutability' do
    context "returns true iff api methods and inherited methods match exactly to the other object's methods. Examples:" do
      context "a surrogate with no api methods" do
        let(:surrogate) { Surrogate.endow Class.new }

        example "is substitutable for a class with no methods" do
          surrogate.should substitute_for Class.new
        end

        example "is not substitutable for a class with instance methods" do
          surrogate.should_not substitute_for Class.new { def foo()end }
        end

        example "is not substitutable for a class with class methods" do
          surrogate.should_not substitute_for Class.new { def self.foo()end }
        end

        example "is not substitutable for a class with inherited instance methods" do
          parent = Class.new { def foo()end }
          surrogate.should_not substitute_for Class.new(parent)
        end

        example "is not substitutable for a class with inherited class methods" do
          parent = Class.new { def self.foo()end }
          surrogate.should_not substitute_for Class.new(parent)
        end
      end


      context "a surrogate with an instance level api method" do
        let(:surrogate) { Class.new { Surrogate.endow self; define :foo } }

        example "is substitutable for a class with the same method" do
          surrogate.should substitute_for Class.new { def foo()end }
        end

        example "is substitutable for a class that inherits the method" do
          parent = Class.new { def foo()end }
          surrogate.should substitute_for Class.new(parent)
        end

        example "is not substitutable for a class without the method" do
          surrogate.should_not substitute_for Class.new
        end

        example "is not substitutable for a class with a different method" do
          surrogate.should_not substitute_for Class.new { def bar()end }
        end

        example "is not substitutable for a class with additional methods" do
          other = Class.new { def foo()end; def bar()end }
          surrogate.should_not substitute_for other
        end

        example "is not substitutable for a class with the method and inerited additional methods" do
          parent = Class.new { def bar()end }
          surrogate.should_not substitute_for Class.new(parent) { def foo()end }
        end

        example "is not substitutable for a class with the method and additional class methods" do
          surrogate.should_not substitute_for Class.new { def foo()end; def self.bar()end }
        end

        example "is not substitutable for a class with the method and inherited additional class methods" do
          parent = Class.new { def self.bar()end }
          surrogate.should_not substitute_for Class.new(parent) { def foo()end }
        end
      end


      describe "it has helpful error messages" do
        let(:surrogate) { Surrogate.endow Class.new }

        specify 'when klass is missing an instance method' do
          surrogate.define :meth
          expect { surrogate.should substitute_for Class.new }.to \
            raise_error(RSpec::Expectations::ExpectationNotMetError, "Was not substitutable because surrogate has extra instance methods: [:meth]")
        end

        specify 'when klass is missing a class method' do
          surrogate = Surrogate.endow(Class.new) { define :meth }
          expect { surrogate.should substitute_for Class.new }.to \
            raise_error(RSpec::Expectations::ExpectationNotMetError, "Was not substitutable because surrogate has extra class methods: [:meth]")
        end

        specify 'when surrogate is missing an instance method' do
          klass = Class.new { def meth() end }
          expect { surrogate.should substitute_for klass }.to \
            raise_error(RSpec::Expectations::ExpectationNotMetError, "Was not substitutable because surrogate is missing instance methods: [:meth]")
        end

        specify 'when surrogate is missing a class method' do
          klass = Class.new { def self.meth() end }
          expect { surrogate.should substitute_for klass }.to \
            raise_error(RSpec::Expectations::ExpectationNotMetError, "Was not substitutable because surrogate is missing class methods: [:meth]")
        end

        specify 'when combined' do
          surrogate = Surrogate.endow(Class.new) { define :surrogate_class_meth }.define :surrogate_instance_meth
          klass = Class.new { def self.api_class_meth()end; def api_instance_meth() end }
          expect { surrogate.should substitute_for klass }.to \
            raise_error(RSpec::Expectations::ExpectationNotMetError, "Was not substitutable because surrogate has extra instance methods: [:surrogate_instance_meth], "\
                                                                                                             "has extra class methods: [:surrogate_class_meth], "\
                                                                                                             "is missing instance methods: [:api_instance_meth], "\
                                                                                                             "is missing class methods: [:api_class_meth]")
        end

        specify "when negated (idk why you'd ever want this, though)" do
          expect { surrogate.should_not substitute_for Class.new }.to \
            raise_error(RSpec::Expectations::ExpectationNotMetError, "Should not have been substitute, but was")
        end
      end
    end
  end



  context 'subset substitutability -- specified with subset: true option' do
    context "returns true if api methods and inherited methods match are all implemented by other class. Examples:" do
      example 'true when exact match' do
        Surrogate.endow(Class.new).should substitute_for Class.new, subset: true
      end

      example 'true when other has additional instance methods and class methods' do
        klass = Class.new { def self.class_meth()end; def instance_meth()end }
        Surrogate.endow(Class.new).should substitute_for klass, subset: true
      end

      example 'false when other is missing instance methods' do
        klass = Class.new { def self.extra_method()end; def extra_method()end }
        expect { Surrogate.endow(Class.new).define(:meth).should substitute_for klass, subset:true }.to \
          raise_error(RSpec::Expectations::ExpectationNotMetError, "Was not substitutable because surrogate has extra instance methods: [:meth]")
      end

      example 'false when other is missing class methods' do
        klass = Class.new { def self.extra_method()end; def extra_method()end }
        expect { Surrogate.endow(Class.new) { define :meth }.should substitute_for klass, subset:true }.to \
          raise_error(RSpec::Expectations::ExpectationNotMetError, "Was not substitutable because surrogate has extra class methods: [:meth]")
      end

      example 'false when other is missing instance and class methods' do
        klass = Class.new { def self.extra_method()end; def extra_method()end }
        expect { Surrogate.endow(Class.new) { define :class_meth }.define(:instance_meth).should substitute_for klass, subset: true }.to \
          raise_error(RSpec::Expectations::ExpectationNotMetError,
                      "Was not substitutable because surrogate has extra instance methods: [:instance_meth], has extra class methods: [:class_meth]")
      end
    end
  end



  context 'type substitutability -- specified with types: true/false option (DEFAULTS TO TRUE)' do
    it 'defaults to true' do
      klass = Class.new { def instance_meth(a) end }
      surrogate = Surrogate.endow(Class.new).define(:instance_meth) { }
      surrogate.should_not substitute_for klass
      surrogate.should substitute_for klass, types: false
    end

    it 'disregards when argument names differ' do
      klass = Class.new { def instance_meth(a) end }
      surrogate = Surrogate.endow(Class.new).define(:instance_meth) { |b| }
      surrogate.should substitute_for klass, names: false
    end

    it 'disregards when surrogate has no body for an api method' do
      klass = Class.new { def instance_meth(a) end }
      surrogate = Surrogate.endow(Class.new).define :instance_meth
      surrogate.should substitute_for klass, names: false
    end

    context 'returns true if argument types match exactly. Examples:' do
      example 'true when exact match' do
        klass = Class.new { def instance_meth(a, b=1, *c, d, &e) end }
        surrogate = Surrogate.endow(Class.new).define(:instance_meth) { |a, b=1, *c, d, &e| }
        surrogate.should substitute_for klass
      end

      example 'false when missing block' do
        klass = Class.new { def instance_meth(a, b=1, *c, d) end }
        surrogate = Surrogate.endow(Class.new).define(:instance_meth) { |a, b=1, *c, d, &e| }
        surrogate.should_not substitute_for klass

        klass = Class.new { def instance_meth(a, b=1, *c, d, &e) end }
        surrogate = Surrogate.endow(Class.new).define(:instance_meth) { |a, b=1, *c, d| }
        surrogate.should_not substitute_for klass
      end

      example 'false when missing splatted args' do
        klass = Class.new { def instance_meth(a, b=1, d, &e) end }
        surrogate = Surrogate.endow(Class.new).define(:instance_meth) { |a, b=1, *c, d, &e| }
        surrogate.should_not substitute_for klass

        klass = Class.new { def instance_meth(a, b=1, *c, d, &e) end }
        surrogate = Surrogate.endow(Class.new).define(:instance_meth) { |a, b=1, d, &e| }
        surrogate.should_not substitute_for klass
      end

      example 'false when missing optional args' do
        klass = Class.new { def instance_meth(a, *c, d, &e) end }
        surrogate = Surrogate.endow(Class.new).define(:instance_meth) { |a, b=1, *c, d, &e| }
        surrogate.should_not substitute_for klass

        klass = Class.new { def instance_meth(a, b=1, *c, d, &e) end }
        surrogate = Surrogate.endow(Class.new).define(:instance_meth) { |a, *c, d, &e| }
        surrogate.should_not substitute_for klass
      end

      example 'false when missing required args' do
        klass = Class.new { def instance_meth(b=1, *c, d, &e) end }
        surrogate = Surrogate.endow(Class.new).define(:instance_meth) { |a, b=1, *c, d, &e| }
        surrogate.should_not substitute_for klass

        klass = Class.new { def instance_meth(a, b=1, *c, d, &e) end }
        surrogate = Surrogate.endow(Class.new).define(:instance_meth) { |b=1, *c, d, &e| }
        surrogate.should_not substitute_for klass

        klass = Class.new { def instance_meth(a, b=1, *c, &e) end }
        surrogate = Surrogate.endow(Class.new).define(:instance_meth) { |a, b=1, *c, d, &e| }
        surrogate.should_not substitute_for klass

        klass = Class.new { def instance_meth(a, b=1, *c, d, &e) end }
        surrogate = Surrogate.endow(Class.new).define(:instance_meth) { |a, b=1, *c, &e| }
        surrogate.should_not substitute_for klass
      end
    end
  end
end
