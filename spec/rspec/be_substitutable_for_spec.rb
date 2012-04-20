require 'spec_helper'
require 'surrogate/rspec/substitutability_matchers'

describe 'be_substitutable_for' do

  context "a class with no methods" do
    let(:original_class) { Class.new }
    let(:mocked_class)   { Surrogate.for Class.new }

    it "can be substituable for it" do
      mocked_class.should be_substitutable_for original_class
    end
  end

  context "a class with instance methods" do
    let(:original_class) do
      Class.new do
        def foo
        end

        def bar
        end
      end
    end

    context "when mocked class has no api methods" do
      let(:mocked_class)   { Surrogate.for Class.new }
      it "cannot be substituable for it" do
        mocked_class.should_not be_substitutable_for original_class
      end
    end

    context 'when the mocked class has the same api methods' do
      let(:mocked_class) do
        Class.new do
          Surrogate.for self
          define :foo
          define :bar
        end
      end
      it 'is substituable for it' do
        mocked_class.should be_substitutable_for original_class
      end
    end

    context 'when the mocked class has different api methods' do
      let(:mocked_class) do
        Class.new do
          Surrogate.for self
          define :qux
        end
      end

      it 'is not substituable for it' do
        mocked_class.should_not be_substitutable_for original_class
      end
    end

    context "when the mocked class has an extra api methods" do
      let(:mocked_class) do
        Class.new do
          Surrogate.for self
          define :foo
          define :bar
          define :qux
        end
      end
      it 'is not substituable for it' do
        mocked_class.should_not be_substitutable_for original_class
      end
    end
  end


  context 'a class with class methods' do
    # COPYPASTA

    let(:original_class) do
      Class.new do
        def self.foo
        end

        def self.bar
        end
      end
    end

    context "when mocked class has no api methods" do
      let(:mocked_class)   { Surrogate.for Class.new }
      it "cannot be substituable for it" do
        mocked_class.should_not be_substitutable_for original_class
      end
    end

    context 'when the mocked class has the same api methods' do
      let(:mocked_class) do
        Class.new do
          Surrogate.for self do
            define :foo
            define :bar
          end
        end
      end
      it 'is substituable for it' do
        mocked_class.should be_substitutable_for original_class
      end
    end

    context 'when the mocked class has different api methods' do
      let(:mocked_class) do
        Class.new do
          Surrogate.for self do
            define :qux
          end
        end
      end

      it 'is not substituable for it' do
        mocked_class.should_not be_substitutable_for original_class
      end
    end

    context "when the mocked class has an extra api method" do
      let(:mocked_class) do
        Class.new do
          Surrogate.for self do
            define :foo
            define :bar
            define :qux
          end
        end
      end
      it 'is not substituable for it' do
        mocked_class.should_not be_substitutable_for original_class
      end
    end
  end
end

# inherited methods
# methods on the mock that aren't api methods
# arity
