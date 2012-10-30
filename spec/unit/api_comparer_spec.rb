require 'spec_helper'

describe Surrogate::ApiComparer do

  def set_assertion(set, expectations)
    Array(expectations[:include]).each { |meth| set.should include meth }
    Array(expectations[:exclude]).each { |meth| set.should_not include meth }
  end

  context 'when identifying types' do
    it 'uses :req, :opt, :rest, and :block' do
      surrogate = Surrogate.endow(Class.new).define(:to_s) { |a, b, c, d=1, e=2, *f, g, &h| }
      comparer = described_class.new(Class.new, surrogate)
      comparer.compare[:instance][:types][:to_s][:surrogate].should ==
        [:req, :req, :req, :opt, :opt, :rest, :req, :block]
    end
  end

  describe 'its knowlege about the surrogate' do

    let :surrogate do
      parent = Class.new do
        def inherited_instance_meth()end
        def inherited_instance_meth_with_signature(a1, b1=1, *c1, d1, &e1)end
        def self.inherited_class_meth()end
        def self.inherited_class_meth_with_signature(a2, b2=1, *c2, d2, &e2)end
      end

      Class.new parent do
        Surrogate.endow self do
          define :api_class_meth
          define(:api_class_meth_with_signature) { |a3, b3=1, *c3, d3, &e3| }
          def class_meth()end
          def self.class_meth_with_signature(a4, b4=1, *c4, d4, &e4)end
        end
        define :api_instance_meth
        define(:api_instance_meth_with_signature) { |a5, b5=1, *c5, d5, &e5| }
        def instance_meth()end
        def instance_meth_with_signature(a6, b6=1, *c6, d6, &e6)end
      end
    end

    let(:comparer) { described_class.new Class.new, surrogate }

    it "knows the surrogate's instance level api methods" do
      comparer.surrogate_methods[:instance][:api].should == Set[:api_instance_meth, :api_instance_meth_with_signature]
    end

    it "knows the surrogate's inherited instance methods" do
      set_assertion comparer.surrogate_methods[:instance][:inherited],
        include: [:inherited_instance_meth],
        exclude: [:api_instance_meth, :instance_meth, :class_meth, :inherited_class_meth, :api_class_meth]
    end

    it "knows the surrogate's other instance methods" do
      set_assertion comparer.surrogate_methods[:instance][:other],
        include: [:instance_meth],
        exclude: [:inherited_instance_meth, :api_instance_meth, :class_meth, :inherited_class_meth, :api_class_meth]
    end

    it "knows the surrogate's class level api methods" do
      comparer.surrogate_methods[:class][:api].should == Set[:api_class_meth, :api_class_meth_with_signature]
    end

    it "knows the surrogate's inherited class methods" do
      # show new explicitly as we override it in lib
      set_assertion comparer.surrogate_methods[:class][:inherited],
        include: [:inherited_class_meth, :new],
        exclude: [:api_instance_meth, :instance_meth, :class_meth, :inherited_instance_meth, :api_class_meth]
    end

    it "knows the surrogate's other class methods" do
      # show new explicitly as we override it in lib
      set_assertion comparer.surrogate_methods[:class][:other],
        include: [:class_meth],
        exclude: [:new, :api_instance_meth, :instance_meth, :inherited_instance_meth, :api_class_meth, :inherited_class_meth]
    end
  end


  describe 'its knowledge about the other object' do
    let(:surrogate) { Surrogate.endow Class.new }

    let :actual do
      parent = Class.new { def self.inherited_class_meth()end; def inherited_instance_meth()end }
      Class.new(parent) { def self.class_meth()end; def instance_meth()end }
    end

    let(:comparer) { described_class.new actual, surrogate }

    it "knows the object's inherited instance methods" do
      set_assertion comparer.actual_methods[:instance][:inherited],
        include: [:inherited_instance_meth],
        exclude: [:inherited_class_meth, :class_meth, :instance_meth]
    end

    it "knows the objects other instance methods" do
      comparer.actual_methods[:instance][:other].should == Set[:instance_meth]
    end

    it "knows the object's inherited class methods" do
      set_assertion comparer.actual_methods[:class][:inherited],
        include: [:inherited_class_meth],
        exclude: [:inherited_instance_meth, :class_meth, :instance_meth]
    end

    it "knows the object's other class methods" do
      comparer.actual_methods[:class][:other].should == Set[:class_meth]
    end
  end


  describe '#compare' do
    let(:parent) { Class.new { def inherited_instance_not_on_surrogate()end; def self.inherited_class_not_on_surrogate()end } }

    let :actual do
      Class.new parent do
        def instance_not_on_surrogate()end
        def self.class_not_on_surrogate()end
        def instance_meth_on_both()end
        def self.class_meth_on_both()end
      end
    end

    let :surrogate do
      Class.new do
        Surrogate.endow(self) { define :class_not_on_actual }
        define :instance_not_on_actual
        def instance_meth_on_both()end
        def self.class_meth_on_both()end
      end
    end

    let(:comparer) { described_class.new actual, surrogate }

    it 'tells me about instance methods on actual that are not on surrogate' do
      comparer.compare[:instance][:not_on_surrogate].should == Set[:instance_not_on_surrogate, :inherited_instance_not_on_surrogate, :instance_meth_on_both]
    end

    it 'tells me about class methods on actual that are not on surrogate' do
      comparer.compare[:class][:not_on_surrogate].should == Set[:class_not_on_surrogate, :inherited_class_not_on_surrogate, :class_meth_on_both]
    end

    it 'tells me about api instance methods on surrogate that are not on actual' do
      comparer.compare[:instance][:not_on_actual].should == Set[:instance_not_on_actual]
    end

    it 'tells me about api class methods on surrogate that are not on actual' do
      comparer.compare[:class][:not_on_actual].should == Set[:class_not_on_actual]
    end


    context "it tells me the difference when types don't match. Examples:" do
      example 'nothing when arguments are the same' do
        klass = Class.new do
          def self.class_meth1(a1, b1=1, *c1, &d1)end
          def self.class_meth2(a2, b2=1, *c2, &d2)end
          def self.class_meth3(a3, b3=1, *c3, &d3)end
          def instance_meth1(e1, f1=1, *c1, &d1)end
          def instance_meth2(e2, f2=1, *c2, &d2)end
          def instance_meth3(e3, f3=1, *c3, &d3)end
        end

        parent = Class.new do
          def self.class_meth1(a1, b1=1, *c1, &d1)end
          def instance_meth1(e1, f1=1, *c1, &d1)end
        end

        surrogate = Class.new parent do
          Surrogate.endow self do
            define(:class_meth2) { |a2, b2=1, *c2, &d2| }
          end
          def self.class_meth3(a3, b3=1, *c3, &d3)end
          define(:instance_meth2) { |e2, f2=1, *c2, &d2| }
          def instance_meth3(e3, f3=1, *c3, &d3)end
        end

        comparer = described_class.new klass, surrogate
        comparer.compare[:instance][:types].should  == {}
        comparer.compare[:class][:types].should == {}
      end

      it 'ignores methods that are not on both the surrogate and the actual' do
        klass = Class.new do
          def self.class_meth1(a)end
          def instance_meth1(a, b)end
        end
        surrogate = Class.new do
          Surrogate.endow self do
            define(:class_meth2) { |a, b, c| }
          end
          define(:instance_meth2) { |a, b, c, d| }
        end

        described_class.new(klass, surrogate).compare
        comparer.compare[:class][:types].should == {}
        comparer.compare[:instance][:types].should == {}
      end

      it 'ignores methods with no default block' do
        klass = Class.new { def instance_meth(a)end }
        surrogate = Surrogate.endow(Class.new).define(:instance_meth)
        described_class.new(klass, surrogate).compare
        comparer.compare[:class][:types].should == {}
        comparer.compare[:instance][:types].should == {}
      end

      it 'tells me about class methods with different types' do
        klass = Class.new do
          def self.class_meth1(a, b=1, *c, &d)end
          def self.class_meth2(a, b=1, *c, &d)end
        end
        parent = Class.new { def self.class_meth1(b=1, *c, &d)end }
        surrogate = Class.new parent do
          Surrogate.endow self do
            define(:class_meth2) { |a, *c, &d| }
          end
        end

        comparer = described_class.new klass, surrogate
        comparer.compare[:class][:types].should == {
          class_meth1: { actual:    [:req, :opt, :rest, :block],
                         surrogate: [      :opt, :rest, :block],
          },
          class_meth2: { actual:    [:req, :opt, :rest, :block],
                         surrogate: [:req,       :rest, :block],
          },
        }
      end

      it 'tells me about class methods with different types' do
        klass = Class.new do
          def instance_meth1(a, b=1, *c, &d)end
          def instance_meth2(a, b=1, *c, &d)end
        end
        parent = Class.new { def instance_meth1(b=1, *c, &d)end }
        surrogate = Class.new parent do
          Surrogate.endow self
          define(:instance_meth2) { |a, *c, &d| }
        end

        comparer = described_class.new klass, surrogate
        comparer.compare[:instance][:types].should == {
          instance_meth1: { actual:    [:req, :opt, :rest, :block],
                            surrogate: [      :opt, :rest, :block],
          },
          instance_meth2: { actual:    [:req, :opt, :rest, :block],
                            surrogate: [:req,       :rest, :block],
          },
        }
      end
    end
  end
end
