require 'spec_helper'

describe 'RSpec matchers' do
  let(:mocked_class) { Mockingbird.song_for Class.new }

  describe 'have_been_told_to' do
    describe 'default use case' do
      before { mocked_class.sing :kick, default: [] }
      let(:instance) { mocked_class.new }

      example 'passes if has been invoked at least once' do
        instance.should_not have_been_told_to :kick
        instance.kick
        instance.should have_been_told_to :kick
        instance.kick
        instance.should have_been_told_to :kick
      end

      example 'failure message for should' do
        expect { instance.should have_been_told_to :kick }.to \
          raise_error(RSpec::Expectations::ExpectationNotMetError, /was never told to kick/)
      end

      example 'failure message for should not' do
        instance.kick
        expect { instance.should_not have_been_told_to :kick }.to \
          raise_error(RSpec::Expectations::ExpectationNotMetError, /shouldn't have been told to kick, but was told to kick 1 time/)

        instance.kick
        expect { instance.should_not have_been_told_to :kick }.to \
          raise_error(RSpec::Expectations::ExpectationNotMetError, /shouldn't have been told to kick, but was told to kick 2 times/)
      end
    end


    describe 'specifying which arguments it should have been invoked with' do
      before { mocked_class.sing :smile, default: nil }
      let(:instance) { mocked_class.new }

      example 'default use case' do
        instance.should_not have_been_told_to(:smile).with(1, 2, 3)
        instance.smile 1, 2
        instance.should_not have_been_told_to(:smile).with(1, 2, 3)
        instance.smile 1, 2, 3
        instance.should have_been_told_to(:smile).with(1, 2, 3)
      end

      example 'failure message for should' do
        expect { instance.should have_been_told_to(:smile).with(1, '2') }.to \
          raise_error(RSpec::Expectations::ExpectationNotMetError, /should have been told to smile with `1, "2"', but was never invoked/)

        instance.smile 3
        instance.smile 4, '5'
        expect { instance.should have_been_told_to(:smile).with(1, '2') }.to \
          raise_error(RSpec::Expectations::ExpectationNotMetError, /should have been told to smile with `1, "2"', but got `3', `4, "5"'/)
      end

      example 'failure message for should not' do
        instance.smile 1, '2'
        expect { instance.should_not have_been_told_to(:smile).with(1, '2') }.to \
          raise_error(RSpec::Expectations::ExpectationNotMetError, /should not have been told to smile with `1, "2"'/)
      end
    end


    describe 'specifying number of times invoked' do
      before { mocked_class.sing :wink, default: nil }
      let(:instance) { mocked_class.new }

      example 'default use case' do
        instance.should have_been_told_to(:wink).times(0)
        instance.wink
        instance.should have_been_told_to(:wink).times(1)
        instance.wink
        instance.should have_been_told_to(:wink).times(2)
      end

      example 'failure message for should' do
        expect { instance.should have_been_told_to(:wink).times(1) }.to \
          raise_error(RSpec::Expectations::ExpectationNotMetError, /should have been told to wink 1 time but was told to wink 0 times/)

        instance.wink
        expect { instance.should have_been_told_to(:wink).times(2) }.to \
          raise_error(RSpec::Expectations::ExpectationNotMetError, /should have been told to wink 2 times but was told to wink 1 time/)
      end

      example 'failure message for should not' do
        expect { instance.should_not have_been_told_to(:wink).times(0) }.to \
          raise_error(RSpec::Expectations::ExpectationNotMetError, /shouldn't have been told to wink 0 times, but was/)

        instance.wink
        expect { instance.should_not have_been_told_to(:wink).times(1) }.to \
          raise_error(RSpec::Expectations::ExpectationNotMetError, /shouldn't have been told to wink 1 time, but was/)
      end
    end
  end


  describe 'conjunction of with(args) and times(n)' do
    before { mocked_class.sing :wink, default: nil }
    let(:instance) { mocked_class.new }

    example 'default use case' do
      instance.should have_been_told_to(:wink).times(0).with(1, '2')
      instance.should_not have_been_told_to(:wink).times(1).with(1, '2')
      instance.wink
      instance.should have_been_told_to(:wink).times(0).with(1, '2')
      instance.should_not have_been_told_to(:wink).times(1).with(1, '2')
      instance.wink 1, '2'
      instance.should have_been_told_to(:wink).times(1).with(1, '2')
      instance.wink 1, '2' # correct one
      instance.wink 1, '3'
      instance.wink 2, '2'
      instance.wink 1, '2', 3
      instance.should have_been_told_to(:wink).times(2).with(1, '2')
      instance.should have_been_told_to(:wink).with(1, '2').times(2)
    end

    example 'failure message for should' do
      expect { instance.should have_been_told_to(:wink).times(1).with(1, '2') }.to \
        raise_error(RSpec::Expectations::ExpectationNotMetError, /should have been told to wink 1 time with `1, "2"', but was never told to/)

      instance.wink 1, '2'
      expect { instance.should have_been_told_to(:wink).times(0).with(1, '2') }.to \
        raise_error(RSpec::Expectations::ExpectationNotMetError, /should have been told to wink 0 times with `1, "2"', but got it 1 time/)

      instance.wink 1, '2'
      expect { instance.should have_been_told_to(:wink).times(1).with(1, '2') }.to \
        raise_error(RSpec::Expectations::ExpectationNotMetError, /should have been told to wink 1 time with `1, "2"', but got it 2 times/)
    end

    example 'failure message for should not' do
      instance.wink 1, '2'
      instance.wink 1, '2'
      expect { instance.should_not have_been_told_to(:wink).times(2).with(1, '2') }.to \
        raise_error(RSpec::Expectations::ExpectationNotMetError, /should not have been told to wink 2 times with `1, "2"'/)
    end
  end


  describe 'have_been_initialized_with' do
    before { mocked_class.module_eval { def initialize(*) end } } # b/c 1.9.3 will have arity issues otherwise

    it 'is the same as have_been_told_to(:initialize).with(...)' do
      mocked_class.new.should have_been_initialized_with no_args
      mocked_class.new.should_not have_been_initialized_with(1)
      mocked_class.new(1).should have_been_initialized_with 1
      mocked_class.new(1, '2').should have_been_initialized_with 1, '2'
    end

    def failure_message_for
      yield
    rescue RSpec::Expectations::ExpectationNotMetError
      $!.message
    end

    example 'failure message for should' do
      failure_message_for { mocked_class.new("1").should have_been_initialized_with 2 }.should ==
        failure_message_for { mocked_class.new("1").should have_been_told_to(:initialize).with(2) }
    end

    example 'failure message for should not' do
      failure_message_for { mocked_class.new("1").should_not have_been_initialized_with('1') }.should ==
        failure_message_for { mocked_class.new("1").should_not have_been_told_to(:initialize).with('1') }
    end
  end
end
