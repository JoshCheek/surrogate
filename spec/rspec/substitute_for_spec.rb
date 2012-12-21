require 'spec_helper'

describe 'substutability matchers' do
  context 'understand that the non-surrogate class should substitute for the surrogate class when' do
    specify 'the surrogate class comes first' do
      surrogate = Surrogate.endow(Class.new).define(:some_meth)
      surrogate.should_not substitute_for Class.new
      surrogate.should_not be_substitutable_for Class.new
      surrogate.should substitute_for Class.new { def some_meth() end }
      surrogate.should be_substitutable_for Class.new { def some_meth() end }
    end

    it 'the non-surrogate class comes first' do
      Kernel.should_not_receive :warn
      surrogate = Surrogate.endow(Class.new).define(:some_meth)
      Class.new.should_not substitute_for surrogate
      Class.new.should_not be_substitutable_for surrogate
      Class.new { def some_meth() end }.should substitute_for surrogate
      Class.new { def some_meth() end }.should be_substitutable_for surrogate
    end
  end

  context 'exact substitutability' do
    context "returns true iff api methods and inherited methods match exactly to the other object's methods. Examples:" do
      context "a surrogate with no api methods" do
        let(:surrogate) { Surrogate.endow Class.new }

        example "is substitutable for a class with no methods" do
          Class.new.should substitute_for surrogate
        end

        example "is not substitutable for a class with instance methods" do
          Class.new { def foo()end }.should_not substitute_for surrogate
        end

        example "is not substitutable for a class with class methods" do
          Class.new { def self.foo()end }.should_not substitute_for surrogate
        end

        example "is not substitutable for a class with inherited instance methods" do
          parent = Class.new { def foo()end }
          Class.new(parent).should_not substitute_for surrogate
        end

        example "is not substitutable for a class with inherited class methods" do
          parent = Class.new { def self.foo()end }
          Class.new(parent).should_not substitute_for surrogate
        end
      end


      context "a surrogate with an instance level api method" do
        let(:surrogate) { Class.new { Surrogate.endow self; define :foo } }

        example "is substitutable for a class with the same method" do
          Class.new { def foo()end }.should substitute_for surrogate
        end

        example "is substitutable for a class that inherits the method" do
          parent = Class.new { def foo()end }
          Class.new(parent).should substitute_for surrogate
        end

        example "is not substitutable for a class without the method" do
          Class.new.should_not substitute_for surrogate
        end

        example "is not substitutable for a class with a different method" do
          Class.new { def bar()end }.should_not substitute_for surrogate
        end

        example "is not substitutable for a class with additional methods" do
          other = Class.new { def foo()end; def bar()end }
          other.should_not substitute_for surrogate
        end

        example "is not substitutable for a class with the method and inerited additional methods" do
          parent = Class.new { def bar()end }
          Class.new(parent) { def foo()end }.should_not substitute_for surrogate
        end

        example "is not substitutable for a class with the method and additional class methods" do
          Class.new { def foo()end; def self.bar()end }.should_not substitute_for surrogate
        end

        example "is not substitutable for a class with the method and inherited additional class methods" do
          parent = Class.new { def self.bar()end }
          Class.new(parent) { def foo()end }.should_not substitute_for surrogate
        end
      end


      describe "it has helpful error messages" do
        let(:surrogate) { Surrogate.endow Class.new }

        specify 'when klass is missing an instance method' do
          surrogate.define :meth
          expect { Class.new.should substitute_for surrogate }.to \
            raise_error(RSpec::Expectations::ExpectationNotMetError, "Was not substitutable because surrogate has extra instance methods: [:meth]")
        end

        specify 'when klass is missing a class method' do
          surrogate = Surrogate.endow(Class.new) { define :meth }
          expect { Class.new.should substitute_for surrogate }.to \
            raise_error(RSpec::Expectations::ExpectationNotMetError, "Was not substitutable because surrogate has extra class methods: [:meth]")
        end

        specify 'when surrogate is missing an instance method' do
          klass = Class.new { def meth() end }
          expect { klass.should substitute_for surrogate }.to \
            raise_error(RSpec::Expectations::ExpectationNotMetError, "Was not substitutable because surrogate is missing instance methods: [:meth]")
        end

        specify 'when surrogate is missing a class method' do
          klass = Class.new { def self.meth() end }
          expect { klass.should substitute_for surrogate }.to \
            raise_error(RSpec::Expectations::ExpectationNotMetError, "Was not substitutable because surrogate is missing class methods: [:meth]")
        end

        specify 'when combined' do
          surrogate = Surrogate.endow(Class.new) { define :surrogate_class_meth }.define :surrogate_instance_meth
          klass = Class.new { def self.api_class_meth()end; def api_instance_meth() end }
          expect { klass.should substitute_for surrogate }.to \
            raise_error(RSpec::Expectations::ExpectationNotMetError, "Was not substitutable because surrogate has extra instance methods: [:surrogate_instance_meth]\n"\
                                                                                                             "has extra class methods: [:surrogate_class_meth]\n"\
                                                                                                             "is missing instance methods: [:api_instance_meth]\n"\
                                                                                                             "is missing class methods: [:api_class_meth]")
        end

        specify "when negated (idk why you'd ever want this, though)" do
          expect { Class.new.should_not substitute_for surrogate }.to \
            raise_error(RSpec::Expectations::ExpectationNotMetError, "Should not have been substitute, but was")
        end
      end
    end
  end



  context 'subset substitutability -- specified with subset: true option' do
    context "returns true if api methods and inherited methods match are all implemented by other class. Examples:" do
      example 'true when exact match' do
        Class.new.should substitute_for Surrogate.endow(Class.new), subset: true
      end

      example 'true when other has additional instance methods and class methods' do
        klass = Class.new { def self.class_meth()end; def instance_meth()end }
        klass.should substitute_for Surrogate.endow(Class.new), subset: true
      end

      example 'false when other is missing instance methods' do
        klass     = Class.new { def self.extra_method()end; def extra_method()end }
        surrogate = Surrogate.endow(Class.new).define(:meth)
        expect { klass.should substitute_for surrogate, subset:true }.to \
          raise_error(RSpec::Expectations::ExpectationNotMetError, "Was not substitutable because surrogate has extra instance methods: [:meth]")
      end

      example 'false when other is missing class methods' do
        klass     = Class.new { def self.extra_method()end; def extra_method()end }
        surrogate = Surrogate.endow(Class.new) { define :meth }
        expect { klass.should substitute_for surrogate, subset:true }.to \
          raise_error(RSpec::Expectations::ExpectationNotMetError, "Was not substitutable because surrogate has extra class methods: [:meth]")
      end

      example 'false when other is missing instance and class methods' do
        klass = Class.new { def self.extra_method()end; def extra_method()end }
        surrogate = Surrogate.endow(Class.new) { define :class_meth }.define(:instance_meth)
        expect { klass.should substitute_for surrogate, subset: true }.to \
          raise_error(RSpec::Expectations::ExpectationNotMetError,
                      "Was not substitutable because surrogate has extra instance methods: [:instance_meth]\nhas extra class methods: [:class_meth]")
      end
    end
  end



  context 'type substitutability -- specified with types: true/false option (DEFAULTS TO TRUE)' do
    it 'is turned on by default' do
      klass = Class.new { def instance_meth(a) end }
      surrogate = Surrogate.endow(Class.new).define(:instance_meth) { }
      klass.should_not substitute_for surrogate
      klass.should substitute_for surrogate, types: false
    end

    it 'disregards when argument names differ' do
      klass = Class.new { def instance_meth(a) end }
      surrogate = Surrogate.endow(Class.new).define(:instance_meth) { |b| }
      klass.should substitute_for surrogate, names: false, types: true
    end

    it 'disregards when surrogate has no body for an api method' do
      klass = Class.new { def instance_meth(a) end }
      surrogate = Surrogate.endow(Class.new).define :instance_meth
      klass.should substitute_for surrogate, types: true
    end

    it 'disregards when real object has natively implemented methods that cannot be reflected on' do
      Array.method(:[]).parameters.should == [[:rest]] # make sure Array signatures aren't changing across versions or something
      Array.instance_method(:insert).parameters.should == [[:rest]]
      surrogate = Surrogate.endow(Class.new) { define(:[]) { |a,b,c| } }.define(:insert) { |a,b,c| }
      Array.should substitute_for surrogate, subset: true, types: true
    end

    context 'returns true if argument types match exactly. Examples:' do
      example 'true when exact match' do
        klass = Class.new { def instance_meth(a, b=1, *c, d, &e) end }
        surrogate = Surrogate.endow(Class.new).define(:instance_meth) { |a, b=1, *c, d, &e| }
        klass.should substitute_for surrogate, types: true
      end

      example 'false when missing block' do
        klass = Class.new { def instance_meth(a, b=1, *c, d) end }
        surrogate = Surrogate.endow(Class.new).define(:instance_meth) { |a, b=1, *c, d, &e| }
        klass.should_not substitute_for surrogate, types: true

        klass = Class.new { def instance_meth(a, b=1, *c, d, &e) end }
        surrogate = Surrogate.endow(Class.new).define(:instance_meth) { |a, b=1, *c, d| }
        klass.should_not substitute_for surrogate, types: true
      end

      example 'false when missing splatted args' do
        klass = Class.new { def instance_meth(a, b=1, d, &e) end }
        surrogate = Surrogate.endow(Class.new).define(:instance_meth) { |a, b=1, *c, d, &e| }
        klass.should_not substitute_for surrogate, types: true

        klass = Class.new { def instance_meth(a, b=1, *c, d, &e) end }
        surrogate = Surrogate.endow(Class.new).define(:instance_meth) { |a, b=1, d, &e| }
        klass.should_not substitute_for surrogate
      end

      example 'false when missing optional args' do
        klass = Class.new { def instance_meth(a, *c, d, &e) end }
        surrogate = Surrogate.endow(Class.new).define(:instance_meth) { |a, b=1, *c, d, &e| }
        klass.should_not substitute_for surrogate

        klass = Class.new { def instance_meth(a, b=1, *c, d, &e) end }
        surrogate = Surrogate.endow(Class.new).define(:instance_meth) { |a, *c, d, &e| }
        klass.should_not substitute_for surrogate, types: true
      end

      example 'false when missing required args' do
        klass = Class.new { def instance_meth(b=1, *c, d, &e) end }
        surrogate = Surrogate.endow(Class.new).define(:instance_meth) { |a, b=1, *c, d, &e| }
        klass.should_not substitute_for surrogate, types: true

        klass = Class.new { def instance_meth(a, b=1, *c, d, &e) end }
        surrogate = Surrogate.endow(Class.new).define(:instance_meth) { |b=1, *c, d, &e| }
        klass.should_not substitute_for surrogate, types: true

        klass = Class.new { def instance_meth(a, b=1, *c, &e) end }
        surrogate = Surrogate.endow(Class.new).define(:instance_meth) { |a, b=1, *c, d, &e| }
        klass.should_not substitute_for surrogate, types: true

        klass = Class.new { def instance_meth(a, b=1, *c, d, &e) end }
        surrogate = Surrogate.endow(Class.new).define(:instance_meth) { |a, b=1, *c, &e| }
        klass.should_not substitute_for surrogate, types: true
      end
    end
  end


  context 'name substitutability -- specified with names: true/false option (DEFAULTS TO FALSE)' do
    it 'is turned off by default' do
      # instance
      klass = Class.new { def instance_meth(a) end }
      surrogate = Surrogate.endow(Class.new).define(:instance_meth) {|b|}
      klass.should substitute_for surrogate
      klass.should_not substitute_for surrogate, names: true

      # class
      klass = Class.new { def self.class_meth(a) end }
      surrogate = Surrogate.endow(Class.new) { define(:class_meth) {|b|} }
      klass.should substitute_for surrogate
      klass.should_not substitute_for surrogate, names: true
    end

    it 'disregards when argument types differ' do
      # instance
      klass = Class.new { def instance_meth(a=1) end }
      surrogate = Surrogate.endow(Class.new).define(:instance_meth) {|a|}
      klass.should substitute_for surrogate, types: false, names: true

      # class
      klass = Class.new { def self.class_meth(a=1) end }
      surrogate = Surrogate.endow(Class.new) { define(:class_meth) {|a|} }
      klass.should substitute_for surrogate, types: false, names: true
    end

    it 'disregards when surrogate has no body for an api method' do
      # instance
      klass = Class.new { def instance_meth(a) end }
      surrogate = Surrogate.endow(Class.new).define(:instance_meth)
      klass.should substitute_for surrogate, names: true

      # class
      klass = Class.new { def self.class_meth(a) end }
      surrogate = Surrogate.endow(Class.new) { define :class_meth }
      klass.should substitute_for surrogate, names: true
    end

    it 'disregards when real object has natively implemented methods that cannot be reflected on' do
      Array.method(:[]).parameters.should == [[:rest]] # make sure Array signatures aren't changing across versions or something
      Array.instance_method(:insert).parameters.should == [[:rest]]
      surrogate = Surrogate.endow(Class.new) { define(:[]) { |a,b,c| } }.define(:insert) { |a,b,c| }
      Array.should substitute_for surrogate, subset: true, names: true
    end

    context 'returns true if argument names match exactly. Examples:' do
      specify 'true when exact match' do
        klass = Class.new do
          def self.class_meth(a) end
          def instance_meth(b) end
        end
        surrogate = Surrogate.endow(Class.new) { define(:class_meth) {|a|} }.define(:instance_meth) {|b|}
        klass.should substitute_for surrogate, names: true
      end

      specify 'false when different number of args' do
        # instance
        klass = Class.new { def instance_meth(a, b=1, *c, d, &e) end }
        surrogate = Surrogate.endow(Class.new).define(:instance_meth) { |a, b=1, *c, d| }
        klass.should_not substitute_for surrogate, names: true

        # class
        klass = Class.new { def self.class_meth(a, b=1, *c, d, &e) end }
        surrogate = Surrogate.endow(Class.new) { define(:class_meth) { |a, b=1, *c, d| } }
        klass.should_not substitute_for surrogate, names: true
      end

      specify 'false when different names' do
        # instance
        klass = Class.new { def instance_meth(a, b=1, *c, d, &e) end }
        surrogate = Surrogate.endow(Class.new).define(:instance_meth) { |a, b=1, *c, d, &not_e| }
        klass.should_not substitute_for surrogate, names: true

        # class
        klass = Class.new { def instance_meth(a, b=1, *c, d, &e) end }
        surrogate = Surrogate.endow(Class.new) { define(:class_meth) { |a, b=1, *c, d, &not_e| } }
        klass.should_not substitute_for surrogate, names: true
      end
    end
  end
end
