require 'spec_helper'

describe 'RSpec matchers', 'have_been_asked_for_its' do
  let(:mocked_class) { Mockingbird.song_for Class.new }
  let(:instance) { mocked_class.new }

  # EVERYTHING BELOW THIS LINE WAS COPY/PASTED AND IS SUSPECT
  describe 'default use case' do
    before { mocked_class.sing :name, default: 'Ayaan' }

    example 'passes if has been invoked at least once' do
      instance.should_not have_been_asked_for_its :name
      instance.name
      instance.should have_been_asked_for_its :name
      instance.name
      instance.should have_been_asked_for_its :name
    end

    example 'failure message for should' do
      expect { instance.should have_been_asked_for_its :name }.to \
        raise_error(RSpec::Expectations::ExpectationNotMetError, /was never told to name/)
    end

    example 'failure message for should not' do
      instance.name
      expect { instance.should_not have_been_asked_for_its :name }.to \
        raise_error(RSpec::Expectations::ExpectationNotMetError, /shouldn't have been told to name, but was told to name 1 time/)

      instance.name
      expect { instance.should_not have_been_asked_for_its :name }.to \
        raise_error(RSpec::Expectations::ExpectationNotMetError, /shouldn't have been told to name, but was told to name 2 times/)
    end
  end


  describe 'specifying which arguments it should have been invoked with' do
    before { mocked_class.sing :size, default: nil }

    example 'default use case' do
      instance.should_not have_been_asked_for_its(:size).with(1, 2, 3)
      instance.size 1, 2
      instance.should_not have_been_asked_for_its(:size).with(1, 2, 3)
      instance.size 1, 2, 3
      instance.should have_been_asked_for_its(:size).with(1, 2, 3)
    end

    example 'failure message for should' do
      expect { instance.should have_been_asked_for_its(:size).with(1, '2') }.to \
        raise_error(RSpec::Expectations::ExpectationNotMetError, /should have been told to size with `1, "2"', but was never invoked/)

      instance.size 3
      instance.size 4, '5'
      expect { instance.should have_been_asked_for_its(:size).with(1, '2') }.to \
        raise_error(RSpec::Expectations::ExpectationNotMetError, /should have been told to size with `1, "2"', but got `3', `4, "5"'/)
    end

    example 'failure message for should not' do
      instance.size 1, '2'
      expect { instance.should_not have_been_asked_for_its(:size).with(1, '2') }.to \
        raise_error(RSpec::Expectations::ExpectationNotMetError, /should not have been told to size with `1, "2"'/)
    end
  end


  describe 'specifying number of times invoked' do
    before { mocked_class.sing :value, default: nil }

    example 'default use case' do
      instance.should have_been_asked_for_its(:value).times(0)
      instance.value
      instance.should have_been_asked_for_its(:value).times(1)
      instance.value
      instance.should have_been_asked_for_its(:value).times(2)
    end

    example 'failure message for should' do
      expect { instance.should have_been_asked_for_its(:value).times(1) }.to \
        raise_error(RSpec::Expectations::ExpectationNotMetError, /should have been told to value 1 time but was told to value 0 times/)

      instance.value
      expect { instance.should have_been_asked_for_its(:value).times(2) }.to \
        raise_error(RSpec::Expectations::ExpectationNotMetError, /should have been told to value 2 times but was told to value 1 time/)
    end

    example 'failure message for should not' do
      expect { instance.should_not have_been_asked_for_its(:value).times(0) }.to \
        raise_error(RSpec::Expectations::ExpectationNotMetError, /shouldn't have been told to value 0 times, but was/)

      instance.value
      expect { instance.should_not have_been_asked_for_its(:value).times(1) }.to \
        raise_error(RSpec::Expectations::ExpectationNotMetError, /shouldn't have been told to value 1 time, but was/)
    end
  end

  describe 'conjunction of with(args) and times(n)' do
    before { mocked_class.sing :value, default: nil }

    example 'default use case' do
      instance.should have_been_asked_for_its(:value).times(0).with(1, '2')
      instance.should_not have_been_asked_for_its(:value).times(1).with(1, '2')
      instance.value
      instance.should have_been_asked_for_its(:value).times(0).with(1, '2')
      instance.should_not have_been_asked_for_its(:value).times(1).with(1, '2')
      instance.value 1, '2'
      instance.should have_been_asked_for_its(:value).times(1).with(1, '2')
      instance.value 1, '2' # correct one
      instance.value 1, '3'
      instance.value 2, '2'
      instance.value 1, '2', 3
      instance.should have_been_asked_for_its(:value).times(2).with(1, '2')
      instance.should have_been_asked_for_its(:value).with(1, '2').times(2)
    end

    example 'failure message for should' do
      expect { instance.should have_been_asked_for_its(:value).times(1).with(1, '2') }.to \
        raise_error(RSpec::Expectations::ExpectationNotMetError, /should have been told to value 1 time with `1, "2"', but was never told to/)

      instance.value 1, '2'
      expect { instance.should have_been_asked_for_its(:value).times(0).with(1, '2') }.to \
        raise_error(RSpec::Expectations::ExpectationNotMetError, /should have been told to value 0 times with `1, "2"', but got it 1 time/)

      instance.value 1, '2'
      expect { instance.should have_been_asked_for_its(:value).times(1).with(1, '2') }.to \
        raise_error(RSpec::Expectations::ExpectationNotMetError, /should have been told to value 1 time with `1, "2"', but got it 2 times/)
    end

    example 'failure message for should not' do
      instance.value 1, '2'
      instance.value 1, '2'
      expect { instance.should_not have_been_asked_for_its(:value).times(2).with(1, '2') }.to \
        raise_error(RSpec::Expectations::ExpectationNotMetError, /should not have been told to value 2 times with `1, "2"'/)
    end
  end
end
