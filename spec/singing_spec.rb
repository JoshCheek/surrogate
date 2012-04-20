require 'spec_helper'

describe 'define' do
  describe 'in the block' do
    it 'is an api method for the class' do
      pristine_klass = Class.new do
        Surrogate.endow self do
          define(:find) { 123 }
        end
      end

      klass1 = pristine_klass.reprise
      klass1.should_not have_been_told_to :find
      klass1.find(1).should == 123
      klass1.should have_been_told_to(:find).with(1)
    end
  end


  describe 'out of the block' do
    let(:mocked_class) { Surrogate.endow Class.new }
    let(:instance)     { mocked_class.new }

    it 'is an api method for the instance' do
      mocked_class.define(:book) { 'book' }
      instance.book.should == 'book'
    end

    describe 'declaring the behaviour' do
      describe 'for verbs' do
        before     { mocked_class.define :wink }

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

        describe 'will_<api_method>_queue' do
          it 'returns the object' do
            instance = mocked_class.new
            instance.will_wink_queue(1, 2, 3).should equal instance
          end

          context 'it creates a queue of things to find then returns to normal behaviour' do
            specify 'when there is no default block' do
              mock = mocked_class.new
              mock.will_wink_queue :quickly, :slowly
              mock.wink.should == :quickly
              mock.wink.should == :slowly
              expect { mock.wink }.to raise_error Surrogate::UnpreparedMethodError
            end

            specify 'when there is a default block' do
              mocked_class = Surrogate.endow(Class.new)
              mocked_class.define(:connect) { :default }
              mock = mocked_class.new
              mock.will_connect_queue 1, 2
              mock.connect.should == 1
              mock.connect.should == 2
              mock.connect.should == :default
            end
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

        describe 'wil_have_<api_method>_queue' do
          it 'returns the object' do
            instance = mocked_class.new
            instance.will_have_age_queue(1,2,3).should equal instance
          end

          context 'it creates a queue of things to find then returns to normal behaviour' do
            specify 'when there is no default block' do
              mock = mocked_class.new
              mock.will_have_age_queue 12, 34
              mock.age.should == 12
              mock.age.should == 34
              expect { mock.age }.to raise_error Surrogate::UnpreparedMethodError
            end

            specify 'when there is a default block' do
              mocked_class = Surrogate.endow(Class.new)
              mocked_class.define(:name) { 'default' }
              mock = mocked_class.new
              mock.will_have_name_queue 'a', 'b'
              mock.name.should == 'a'
              mock.name.should == 'b'
              mock.name.should == 'default'
            end
          end
        end
      end
    end



    context 'the api method' do
      it 'takes any number of arguments' do
        mocked_class.define(:meth) { 1 }
        mocked_class.new.meth.should == 1
        mocked_class.new.meth(1).should == 1
        mocked_class.new.meth(1, 2).should == 1
      end

      it 'raises an UnpreparedMethodError when it has no default block' do
        mocked_class.define :meth
        expect { mocked_class.new.meth }.to raise_error(Surrogate::UnpreparedMethodError, /meth/)
      end

      it 'considers ivars of the same name to be its default' do
        mocked_class.define :meth
        mocked = mocked_class.new
        mocked.instance_variable_set :@meth, 123
        mocked.meth.should == 123
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
          subclass = Class.new superclass
          mocked_subclass = Surrogate.endow Class.new subclass
          mocked_subclass.define :abc
          mocked_subclass.new.instance_variable_get(:@a).should == 1
        end

        context 'when not an api method' do
          it 'respects arity (this is probably 1.9.3 only)' do
            expect { mocked_class.new(1) }.to raise_error ArgumentError, 'wrong number of arguments(1 for 0)'
          end

          specify 'recorded regardless of when initialize is defined in relation to mock' do
            klass = Class.new do
              Surrogate.endow self
              def initialize(a)
                @a = a
              end
            end
            klass.new(1).should have_been_initialized_with 1
            klass.new(1).instance_variable_get(:@a).should == 1

            klass = Class.new do
              def initialize(a)
                @a = a
              end
              Surrogate.endow self
            end
            klass.new(1).should have_been_initialized_with 1
            klass.new(1).instance_variable_get(:@a).should == 1
          end
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
        mocked_class.define(:meth) { nil }
        mock = mocked_class.new
        mock.meth 1
        mock.meth 1, 2
        mock.meth [1, 2]
        mock.invocations(:meth).should == [
          [1],
          [1, 2],
          [[1, 2]],
        ]
      end

      it 'raises an error if asked about invocations for api methods it does not know' do
        mocked_class.define :meth1
        mocked_class.define :meth2
        mock = mocked_class.new
        expect { mock.invocations(:meth1) }.to_not raise_error
        expect { mock.invocations(:meth3) }.to raise_error Surrogate::UnknownMethod, /doesn't know "meth3", only knows "initialize", "meth1", "meth2"/
      end
    end
  end


  describe 'reprise' do
    it 'a repetition or further performance of the klass' do
      pristine_klass = Class.new do
        Surrogate.endow self do
          define(:find) { 123 }
          define(:bind) { 'abc' }
        end
        define(:peat)   { true }
        define(:repeat) { 321 }
      end

      klass1 = pristine_klass.reprise
      klass1.should_not have_been_told_to :find
      klass1.find(1).should == 123
      klass1.should have_been_told_to(:find).with(1)
      klass1.bind.should == 'abc'

      klass2 = pristine_klass.reprise
      klass2.will_find 456
      klass2.find(2).should == 456
      klass1.find.should == 123

      klass1.should have_been_told_to(:find).with(1)
      klass2.should have_been_told_to(:find).with(2)
      klass1.should_not have_been_told_to(:find).with(2)
      klass2.should_not have_been_told_to(:find).with(1)

      klass1.new.peat.should == true
      klass1.new.repeat.should == 321
    end

    it 'is a subclass of the reprised class' do
      superclass = Surrogate.endow Class.new
      superclass.reprise.new.should be_a_kind_of superclass
    end
  end

  describe '#api_method_names' do
    it 'returns the names of the api methods as symbols' do
      mocked_class = Class.new do
        Surrogate.endow self
        define :abc
      end
      mocked_class.api_method_names.should == [:abc]
    end
  end
end
