require 'mockingbird'
require 'mockingbird/rspec_matchers'

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


    example 'with arguments' do
      pending
      mocked_class.sing :kick, default: []
      mock = mocked_class.new
      mock.kick 1, 2, 3
      mock.should have_been_told_to(:kick).with(1, 2, 3)
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
end
