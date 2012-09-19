require 'spec_helper'

describe 'define' do
  def class_method_names(surrogate)
    Surrogate::SurrogateReflector.new(surrogate).class_api_methods
  end

  def instance_method_names(surrogate)
    Surrogate::SurrogateReflector.new(surrogate).instance_api_methods
  end

  let(:mocked_class) { Surrogate.endow Class.new }
  let(:instance)     { mocked_class.new }

  describe 'in the block' do
    it 'is an api method for the class' do
      pristine_klass = Class.new { Surrogate.endow(self) { define :find } }
      class_method_names(pristine_klass).should == Set[:find]
    end
  end


  describe 'out of the block' do
    it 'is an api method for the instance' do
      mocked_class.define :book
      instance_method_names(mocked_class).should == Set[:book]
    end
  end

  describe 'definition default block invocation' do
    it "is passed the arguments" do
      arg = nil
      mocked_class.define(:meth) { |inner_arg| arg = inner_arg }.new.meth(1212)
      arg.should == 1212
    end

    it "is passed the block" do
      block = nil
      mocked_class.define(:meth) { |&inner_block| block = inner_block }.new.meth { 12 }
      block.call.should == 12
    end

    it "returns the value that the method returns" do
      mocked_class.define(:meth) { 1234 }.new.meth.should == 1234
    end
  end

  describe 'declaring the behaviour' do
    describe 'for verbs' do
      before { mocked_class.define :wink }

      describe 'will_<api_method>' do
        it 'overrides the default value for the api method' do
          mock1 = mocked_class.new
          mock2 = mocked_class.new
          mock1.will_wink :quickly
          mock2.will_wink :slowly
          mock1.wink.should == :quickly
          mock2.wink.should == :slowly
          mock1.wink.should == :quickly
        end

        it 'returns the object' do
          instance = mocked_class.new
          instance.will_wink(:quickly).should equal instance
        end
      end

      describe 'will_<api_method> with multiple arguments' do
        it 'returns the object' do
          instance = mocked_class.new
          instance.will_wink(1, 2, 3).should equal instance
        end

        # Is there something useful the error could say?
        it 'creates a queue of things to find and raises a QueueEmpty error if there are none left' do
          mock = mocked_class.new
          mock.will_wink :quickly, [:slowly]
          mock.wink.should == :quickly
          mock.wink.should == [:slowly]
          expect { mock.wink }.to raise_error Surrogate::Value::ValueQueue::QueueEmpty
        end
      end

      describe 'when an argument is an error' do
        it 'raises the error on method invocation' do
          mocked_class = Surrogate.endow(Class.new)
          mocked_class.define :connect
          mock = mocked_class.new
          error = StandardError.new("some message")

          # for single invocation
          mock.will_connect error
          expect { mock.connect }.to raise_error StandardError, "some message"

          # for queue
          mock.will_connect 1, error, 2
          mock.connect.should == 1
          expect { mock.connect }.to raise_error StandardError, "some message"
          mock.connect.should == 2
        end
      end
    end


    describe 'for nouns' do
      before { mocked_class.define :age }

      describe 'will_have_<api_method>' do
        it 'defines will_have_<api_method> which overrides the default block' do
          mock1 = mocked_class.new
          mock2 = mocked_class.new
          mock1.will_have_age 12
          mock2.will_have_age 34
          mock1.age.should == 12
          mock2.age.should == 34
          mock1.age.should == 12
        end

        it 'returns the object' do
          instance = mocked_class.new
          instance.will_have_age(123).should equal instance
        end
      end

      describe 'wil_have_<api_method> with multiple arguments' do
        it 'returns the object' do
          instance = mocked_class.new
          instance.will_have_age(1,2,3).should equal instance
        end

        # Is there something useful the error could say?
        it 'creates a queue of things to find and raises a QueueEmpty error if there are none left' do
          mock = mocked_class.new
          mock.will_have_age 12, 34
          mock.age.should == 12
          mock.age.should == 34
          expect { mock.age }.to raise_error Surrogate::Value::ValueQueue::QueueEmpty
        end
      end
    end
  end



  context 'the api method' do
    it 'has the same arity as the method' do
      mocked_class.define(:meth) { |a| a }
      mocked_class.new.meth(1).should == 1
      expect { mocked_class.new.meth }.to raise_error ArgumentError, /0 for 1/
      expect { mocked_class.new.meth 1, 2 }.to raise_error ArgumentError, /2 for 1/
    end

    it 'raises an UnpreparedMethodError when it has no default block' do
      mocked_class.define :meth
      expect { mocked_class.new.meth }.to raise_error(Surrogate::UnpreparedMethodError, /meth/)
    end

    it 'considers ivars of the same name to be its default when it has no suffix' do
      mocked_class.define :meth
      mocked = mocked_class.new
      mocked.instance_variable_set :@meth, 123
      mocked.meth.should == 123
    end

    it 'considers ivars ending in _p to be its default when it ends in a question mark' do
      mocked_class.define :meth?
      mocked = mocked_class.new
      mocked.instance_variable_set :@meth_p, 123
      mocked.meth?.should == 123
    end

    it 'reverts to the default block if invoked and having no ivar' do
      mocked_class.define(:meth) { 123 }
      mocked = mocked_class.new
      mocked.instance_variable_get(:@meth).should be_nil
      mocked.meth.should == 123
    end

    describe 'initialization' do
      specify 'api methods can be an initialize method' do
        mocked_class.define(:initialize) { @abc = 123 }
        mocked_class.new.instance_variable_get(:@abc).should == 123
      end

      specify 'initialize exsits even if error is raised' do
        mocked_class.define(:initialize) { raise "simulate runtime error" }
        expect { mocked_class.new }.to raise_error(RuntimeError, /simulate/)
        expect { mocked_class.new }.to raise_error(RuntimeError, /simulate/)
      end

      specify 'receives args' do
        mocked_class.define(:initialize) { |num1, num2| @num = num1 + num2 }
        mocked_class.new(25, 75).instance_variable_get(:@num).should == 100
      end

      specify 'even works with inheritance' do
        superclass = Class.new
        superclass.send(:define_method, :initialize) { @a = 1 }
        subclass = Surrogate.endow Class.new superclass
        subclass.define :abc
        subclass.new.instance_variable_get(:@a).should == 1
      end
    end

    describe 'it takes a block whos return value will be used as the default' do
      specify 'the block is instance evaled' do
        mocked_class.define(:meth) { self }
        instance = mocked_class.new
        instance.meth.should equal instance
      end

      specify 'arguments passed to the method will be passed to the block' do
        mocked_class.define(:meth) { |*args| args }
        instance = mocked_class.new
        instance.meth(1).should == [1]
        instance.meth(1, 2).should == [1, 2]
      end
    end

    it 'remembers what it was invoked with' do
      mocked_class.define(:meth) { |*| nil }
      mock = mocked_class.new
      mock.meth 1
      mock.meth 1, 2
      mock.invocations(:meth).should == [Surrogate::Invocation.new([1]), Surrogate::Invocation.new([1, 2])]

      val = 0
      mock.meth(1, 2) { val =  3 }
      expect { mock.invocations(:meth).last.block.call }.to change { val }.from(0).to(3)
    end

    it 'raises an error if asked about invocations for api methods it does not know' do
      mocked_class.define :meth1
      mocked_class.define :meth2
      mock = mocked_class.new
      expect { mock.invocations(:meth1) }.to_not raise_error
      expect { mock.invocations(:meth3) }.to raise_error Surrogate::UnknownMethod, /doesn't know "meth3", only knows "meth1", "meth2"/
    end
  end


  describe 'clone' do
    example 'acceptance spec' do
      pristine_klass = Class.new do
        Surrogate.endow self do
          define(:find) { |n| 123 }
          define(:bind) { 'abc' }
        end
        define(:peat)   { true }
        define(:repeat) { 321 }
      end

      klass1 = pristine_klass.clone
      klass1.should_not have_been_told_to :find
      klass1.find(1).should == 123
      klass1.should have_been_told_to(:find).with(1)
      klass1.bind.should == 'abc'

      klass2 = pristine_klass.clone
      klass2.will_find 456
      klass2.find(2).should == 456
      klass1.find(3).should == 123

      klass1.should have_been_told_to(:find).with(1)
      klass2.should have_been_told_to(:find).with(2)
      klass1.should_not have_been_told_to(:find).with(2)
      klass2.should_not have_been_told_to(:find).with(1)

      klass1.new.peat.should == true
      klass1.new.repeat.should == 321
    end

    it 'is a subclass of the cloned class' do
      superclass = Surrogate.endow Class.new
      superclass.clone.new.should be_a_kind_of superclass
    end

    describe '.name' do
      it 'is nil for anonymous classes' do
        Surrogate.endow(Class.new).clone.name.should be_nil
      end

      it "is the class's name suffixed with '.clone' for named classes" do
        klass = Surrogate.endow(Class.new)
        self.class.const_set 'Xyz', klass
        klass.clone.name.should == self.class.name + '::Xyz.clone'
      end
    end
  end
end
