require 'spec_helper'

describe 'define' do
  def class_method_names(surrogate)
    Surrogate::SurrogateClassReflector.new(surrogate).class_api_methods
  end

  def instance_method_names(surrogate)
    Surrogate::SurrogateClassReflector.new(surrogate).instance_api_methods
  end

  def invocations(surrogate, method_name)
    Surrogate::SurrogateInstanceReflector.new(surrogate).invocations(method_name)
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

    it "always invokes the block when the method is a setter (ends in '=')" do
      a = 0
      mocked_class.define(:meth=) { |value| a = value }.new.meth = 1234
      a.should == 1234
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
          instance.will_wink(:quickly).should equal instance
        end
      end

      describe 'will_<api_method> with multiple arguments' do
        it 'returns the object' do
          instance.will_wink(1, 2, 3).should equal instance
        end

        # Is there something useful the error could say?
        it 'creates a queue of things to find and raises a QueueEmpty error if there are none left' do
          instance.will_wink :quickly, [:slowly]
          instance.wink.should == :quickly
          instance.wink.should == [:slowly]
          expect { instance.wink }.to raise_error Surrogate::Value::ValueQueue::QueueEmpty
        end
      end

      describe 'will_override(method_name, ...)' do
        it 'returns the object' do
          instance.will_override(:wink, :quickly).should equal instance
        end

        it 'is a dynamic way to override a value (useful for operators)' do
          instance.will_override :wink, :quickly
          instance.wink.should == :quickly
          instance.will_override :wink, :quickly, [:slowly]
          instance.wink.should == :quickly
          instance.wink.should == [:slowly]
        end

        it 'raises an error if you try to override a nonexistent method' do
          expect { instance.will_override :whateva, 123 }
            .to raise_error Surrogate::UnknownMethod, %(doesn't know "whateva", only knows "wink")
          expect { Surrogate.endow(Class.new).new.will_override :whateva, 123 }
            .to raise_error Surrogate::UnknownMethod, %[doesn't know "whateva", doesn't know anything! It's an epistemological conundrum, go define whateva.]
        end
      end

      describe 'when an argument is an error' do
        it 'raises the error on method invocation' do
          mocked_class = Surrogate.endow(Class.new)
          mocked_class.define :connect
          instance = mocked_class.new
          error = StandardError.new("some message")

          # for single invocation
          instance.will_connect error
          expect { instance.connect }.to raise_error StandardError, "some message"

          # for queue
          instance.will_connect 1, error, 2
          instance.connect.should == 1
          expect { instance.connect }.to raise_error StandardError, "some message"
          instance.connect.should == 2
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
          instance.will_have_age(123).should equal instance
        end
      end

      describe 'wil_have_<api_method> with multiple arguments' do
        it 'returns the object' do
          instance.will_have_age(1,2,3).should equal instance
        end

        # Is there something useful the error could say?
        it 'creates a queue of things to find and raises a QueueEmpty error if there are none left' do
          instance.will_have_age 12, 34
          instance.age.should == 12
          instance.age.should == 34
          expect { instance.age }.to raise_error Surrogate::Value::ValueQueue::QueueEmpty
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

    it "can be defined with symbols or strings" do
      mocked_class.define("meth") { |a| a }
      mocked_class.define(:other_meth) { |a| a * 2 }
      mocked_class.new.meth(1).should == 1
      mocked_class.new.other_meth(1).should == 2
    end

    it 'raises an UnpreparedMethodError when it has no default block' do
      mocked_class.define :meth
      expect { instance.meth }.to raise_error Surrogate::UnpreparedMethodError, /meth/
    end

    it 'considers ivars of the same name to be its default when it has no suffix' do
      mocked_class.define :meth
      instance.instance_variable_set :@meth, 123
      instance.meth.should == 123
    end

    it 'considers ivars ending in _p to be its default when it ends in a question mark' do
      mocked_class.define :meth?
      instance.instance_variable_set :@meth_p, 123
      instance.meth?.should == 123
      instance.will_have_meth? 456
      instance.meth?.should == 456
    end

    it 'considers ivars ending in _b to be its default when it ends in a bang' do
      mocked_class.define :meth!
      instance.instance_variable_set :@meth_b, 123
      instance.meth!.should == 123
      instance.will_have_meth! 456
      instance.meth!.should == 456
    end

    it 'reverts to the default block if invoked and having no ivar' do
      mocked_class.define(:meth) { 123 }
      instance.instance_variable_get(:@meth).should be_nil
      instance.meth.should == 123
    end

    it 'raises arity errors, even if the value is overridden' do
      mocked_class.define(:meth) { }
      instance.instance_variable_set :@meth, "abc"
      expect { instance.meth "extra", "args" }.to raise_error ArgumentError, /wrong number of arguments \(2 for 0\)/
    end

    it 'does not raise arity errors, when there is no default block and the value is overridden' do
      mocked_class.define :meth
      mocked = mocked_class.new
      mocked.instance_variable_set :@meth, "abc"
      mocked.meth 1, 2, 3
    end

    it 'can make #initialize an api method' do
      mocked_class.define(:initialize) { @abc = 123 }
      mocked_class.new.instance_variable_get(:@abc).should == 123
    end


    describe 'it takes a block whos return value will be used as the default' do
      specify 'the block is instance evaled' do
        mocked_class.define(:meth) { self }
        instance.meth.should equal instance
      end

      specify 'arguments passed to the method will be passed to the block' do
        mocked_class.define(:meth) { |*args| args }
        instance.meth(1).should == [1]
        instance.meth(1, 2).should == [1, 2]
      end
    end

    it 'remembers what it was invoked with' do
      mocked_class.define(:meth) { |*| nil }
      mock = mocked_class.new
      mock.meth 1
      mock.meth 1, 2
      invocations(mock, :meth).should == [Surrogate::Invocation.new([1]), Surrogate::Invocation.new([1, 2])]

      val = 0
      mock.meth(1, 2) { val =  3 }
      expect { invocations(mock, :meth).last.block.call }.to change { val }.from(0).to(3)
    end

    it 'raises an error if asked about invocations for api methods it does not know' do
      mocked_class.define :meth1
      mocked_class.define :meth2
      expect { invocations instance, :meth1 }.to_not raise_error
      expect { invocations instance, :meth3 }.to raise_error Surrogate::UnknownMethod, /doesn't know "meth3", only knows "meth1", "meth2"/
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

    it 'can be mass initialized by passing a hash of attributes and values when cloning' do
      pristine_klass = Surrogate.endow(Class.new) do
        define(:find) { |n| 123 }
        define(:bind) { 'abc' }
      end
      pristine_klass.clone.find(1).should == 123
      pristine_klass.clone(find: 456, bind: 'def').find(1).should == 456
      pristine_klass.clone.bind.should == 'abc'
      pristine_klass.clone(find: 456, bind: 'def').bind.should == 'def'
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

describe 'defining accessors' do

  specify '#define_reader is an api method for attr_reader' do
    instance = Surrogate.endow(Class.new).define_reader(:eric, :josh).new
    instance.was_not asked_for :eric
    instance.eric.should == nil
    instance.was asked_for :eric
    instance.josh.should be_nil
  end

  specify '#define_reader can be defined with a value' do
    instance = Surrogate.endow(Class.new).define_reader(:eric, :josh) { "is awesome" }.new
    instance.eric.should == "is awesome"
    instance.will_have_eric("less awesome")
    instance.josh.should == "is awesome"
  end

  specify '#define_writer is an api method for attr_writer' do
    instance = Surrogate.endow(Class.new).define_writer(:eric, :josh).new
    instance.was_not told_to :eric=
    instance.eric = "was here"
    instance.instance_variable_get("@eric").should == "was here"
    instance.was told_to :eric=
    instance.josh = "was here"
  end

  specify '#define_accessor is an api method for attr_accessor' do
    instance = Surrogate.endow(Class.new).define_accessor(:eric, :josh).new
    instance.was_not asked_for :eric
    instance.eric.should == nil
    instance.eric = "was here"
    instance.eric.should == "was here"
    instance.was asked_for :eric
    instance.josh = "was also here"
    instance.josh.should == "was also here"
  end

  specify '#define_accessor can take a block for the reader' do
    instance = Surrogate.endow(Class.new).define_accessor(:eric) {"was here"}.new
    instance.was_not asked_for :eric
    instance.eric.should == "was here"
    instance.was asked_for :eric
    instance.eric = "was somewhere else"
    instance.eric.should == "was somewhere else"
  end
end




