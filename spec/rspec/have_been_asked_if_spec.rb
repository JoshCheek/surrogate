require 'spec_helper'

describe 'RSpec matchers', 'have_been_asked_if' do
  let(:mocked_class) { Surrogate.endow(Class.new).define :changed?, default: false }
  let(:instance) { mocked_class.new }

  describe 'default use case' do

    example 'passes if has been invoked at least once' do
      instance.should_not have_been_asked_if :changed?
      instance.changed?
      instance.should have_been_asked_if :changed?
      instance.changed?
      instance.should have_been_asked_if :changed?
    end

    example 'failure message for should' do
      expect { instance.should have_been_asked_if :changed? }.to \
        raise_error(RSpec::Expectations::ExpectationNotMetError, /was never asked if changed?/)
    end

    example 'failure message for should not' do
      instance.changed?
      expect { instance.should_not have_been_asked_if :changed? }.to \
        raise_error(RSpec::Expectations::ExpectationNotMetError, /shouldn't have been asked if changed\?, but was asked 1 time/)

      instance.changed?
      expect { instance.should_not have_been_asked_if :changed? }.to \
        raise_error(RSpec::Expectations::ExpectationNotMetError, /shouldn't have been asked if changed\?, but was asked 2 times/)
    end
  end


  describe 'specifying which arguments it should have been invoked with' do

    example 'default use case' do
      instance.should_not have_been_asked_if(:changed?).with(1, 2, 3)
      instance.changed? 1, 2
      instance.should_not have_been_asked_if(:changed?).with(1, 2, 3)
      instance.changed? 1, 2, 3
      instance.should have_been_asked_if(:changed?).with(1, 2, 3)
    end

    example 'failure message for should' do
      expect { instance.should have_been_asked_if(:changed?).with(1, '2') }.to \
        raise_error(RSpec::Expectations::ExpectationNotMetError, /should have been asked if changed\? with `1, "2"', but was never asked/)

      instance.changed? 3
      instance.changed? 4, '5'
      expect { instance.should have_been_asked_if(:changed?).with(1, '2') }.to \
        raise_error(RSpec::Expectations::ExpectationNotMetError, /should have been asked if changed\? with `1, "2"', but got `3', `4, "5"'/)
    end

    example 'failure message for should not' do
      instance.changed? 1, '2'
      expect { instance.should_not have_been_asked_if(:changed?).with(1, '2') }.to \
        raise_error(RSpec::Expectations::ExpectationNotMetError, /should not have been asked if changed\? with `1, "2"'/)
    end

    describe 'integration with rspec argument_matchers' do
      it 'works with rspec matchers' do
        instance.should_not have_been_asked_if(:changed?).with(no_args)
        instance.changed?(1)
        instance.should_not have_been_asked_if(:changed?).with(no_args)
        instance.changed?
        instance.should have_been_asked_if(:changed?).with(no_args)

        instance.should_not have_been_asked_if(:changed?).with(hash_including all: true)
        instance.changed? any: false, all: true
        instance.should have_been_asked_if(:changed?).with(hash_including all: true)
        instance.should_not have_been_asked_if(:changed?).with(hash_including all: false)
      end
    end
  end


  describe 'specifying number of times invoked' do

    example 'default use case' do
      instance.should have_been_asked_if(:changed?).times(0)
      instance.changed?
      instance.should have_been_asked_if(:changed?).times(1)
      instance.changed?
      instance.should have_been_asked_if(:changed?).times(2)
    end

    example 'failure message for should' do
      expect { instance.should have_been_asked_if(:changed?).times(1) }.to \
        raise_error(RSpec::Expectations::ExpectationNotMetError, /should have been asked if changed\? 1 time, but was asked 0 times/)

      instance.changed?
      expect { instance.should have_been_asked_if(:changed?).times(2) }.to \
        raise_error(RSpec::Expectations::ExpectationNotMetError, /should have been asked if changed\? 2 times, but was asked 1 time/)
    end

    example 'failure message for should not' do
      expect { instance.should_not have_been_asked_if(:changed?).times(0) }.to \
        raise_error(RSpec::Expectations::ExpectationNotMetError, /shouldn't have been asked if changed\? 0 times, but was/)

      instance.changed?
      expect { instance.should_not have_been_asked_if(:changed?).times(1) }.to \
        raise_error(RSpec::Expectations::ExpectationNotMetError, /shouldn't have been asked if changed\? 1 time, but was/)
    end
  end

  describe 'conjunction of with(args) and times(n)' do

    example 'default use case' do
      instance.should have_been_asked_if(:changed?).times(0).with(1, '2')
      instance.should_not have_been_asked_if(:changed?).times(1).with(1, '2')
      instance.changed?
      instance.should have_been_asked_if(:changed?).times(0).with(1, '2')
      instance.should_not have_been_asked_if(:changed?).times(1).with(1, '2')
      instance.changed? 1, '2'
      instance.should have_been_asked_if(:changed?).times(1).with(1, '2')
      instance.changed? 1, '2' # correct one
      instance.changed? 1, '3'
      instance.changed? 2, '2'
      instance.changed? 1, '2', 3
      instance.should have_been_asked_if(:changed?).times(2).with(1, '2')
      instance.should have_been_asked_if(:changed?).with(1, '2').times(2)
    end

    example 'failure message for should' do
      expect { instance.should have_been_asked_if(:changed?).times(1).with(1, '2') }.to \
        raise_error(RSpec::Expectations::ExpectationNotMetError, /should have been asked if changed\? 1 time with `1, "2"', but was never asked/)

      instance.changed? 1, '2'
      expect { instance.should have_been_asked_if(:changed?).times(0).with(1, '2') }.to \
        raise_error(RSpec::Expectations::ExpectationNotMetError, /should have been asked if changed\? 0 times with `1, "2"', but was asked 1 time/)

      instance.changed? 1, '2'
      expect { instance.should have_been_asked_if(:changed?).times(1).with(1, '2') }.to \
        raise_error(RSpec::Expectations::ExpectationNotMetError, /should have been asked if changed\? 1 time with `1, "2"', but was asked 2 times/)
    end

    example 'failure message for should not' do
      instance.changed? 1, '2'
      instance.changed? 1, '2'
      expect { instance.should_not have_been_asked_if(:changed?).times(2).with(1, '2') }.to \
        raise_error(RSpec::Expectations::ExpectationNotMetError, /should not have been asked if changed\? 2 times with `1, "2"'/)
    end
  end
end
