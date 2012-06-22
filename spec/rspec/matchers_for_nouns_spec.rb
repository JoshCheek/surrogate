require 'spec_helper'

shared_examples_for 'a noun matcher' do
  let(:mocked_class) { Surrogate.endow Class.new }
  let(:instance) { mocked_class.new }

  def did_ask(argument, modifiers={})
    assert!(positive_assertion, argument, modifiers)
  end

  def did_not_ask(argument, modifiers={})
    assert!(negative_assertion, argument, modifiers)
  end

  def assert!(assertion, argument, modifiers)
    matcher = send(matcher_name, argument)
    matcher.send(:with, *modifiers[:with]) if modifiers.has_key? :with
    matcher.send(:times, modifiers[:times]) if modifiers.has_key? :times
    instance.send(assertion, matcher)
  end


  describe 'default use case' do
    before { mocked_class.define :name, default: 'Ayaan' }

    example 'passes if has been invoked at least once' do
      did_not_ask :name
      instance.name
      did_ask :name
      instance.name
      did_ask :name
    end

    example 'failure message for should' do
      expect { did_ask :name }.to \
        raise_error(RSpec::Expectations::ExpectationNotMetError, /was never asked for its name/)
    end

    example 'failure message for should not' do
      instance.name
      expect { did_not_ask :name }.to \
        raise_error(RSpec::Expectations::ExpectationNotMetError, /shouldn't have been asked for its name, but was asked 1 time/)

      instance.name
      expect { did_not_ask :name }.to \
        raise_error(RSpec::Expectations::ExpectationNotMetError, /shouldn't have been asked for its name, but was asked 2 times/)
    end
  end


  describe 'specifying which arguments it should have been invoked with' do
    before { mocked_class.define :size, default: nil }

    example 'default use case' do
      did_not_ask :size, with: [1, 2, 3]
      instance.size 1, 2
      did_not_ask :size, with: [1, 2, 3]
      instance.size 1, 2, 3
      did_ask :size, with: [1, 2, 3]
    end

    example 'failure message for should' do
      expect { did_ask :size, with: [1, '2'] }.to \
        raise_error(RSpec::Expectations::ExpectationNotMetError, /should have been asked for its size with `1, "2"', but was never asked/)

      instance.size 3
      instance.size 4, '5'
      expect { did_ask :size, with: [1, '2'] }.to \
        raise_error(RSpec::Expectations::ExpectationNotMetError, /should have been asked for its size with `1, "2"', but got `3', `4, "5"'/)
    end

    example 'failure message for should not' do
      instance.size 1, '2'
      expect { did_not_ask :size, with: [1, '2'] }.to \
        raise_error(RSpec::Expectations::ExpectationNotMetError, /should not have been asked for its size with `1, "2"'/)
    end

    describe 'integration with rspec argument_matchers' do
      it 'works with rspec matchers' do
        did_not_ask :size, with: [no_args]
        instance.size(1)
        did_not_ask :size, with: [no_args]
        instance.size
        did_ask :size, with: [no_args]

        did_not_ask :size, with: [hash_including(all: true)]
        instance.size any: false, all: true
        did_ask     :size, with: [hash_including(all: true)]
        did_not_ask :size, with: [hash_including(all: false)]
      end
    end
  end


  describe 'specifying number of times invoked' do
    before { mocked_class.define :value, default: nil }

    example 'default use case' do
      did_ask :value, times: 0
      instance.value
      did_ask :value, times: 1
      instance.value
      did_ask :value, times: 2
    end

    example 'failure message for should' do
      expect { did_ask :value, times: 1 }.to \
        raise_error(RSpec::Expectations::ExpectationNotMetError, /should have been asked for its value 1 time, but was asked 0 times/)

      instance.value
      expect { did_ask :value, times: 2 }.to \
        raise_error(RSpec::Expectations::ExpectationNotMetError, /should have been asked for its value 2 times, but was asked 1 time/)
    end

    example 'failure message for should not' do
      expect { did_not_ask :value, times: 0 }.to \
        raise_error(RSpec::Expectations::ExpectationNotMetError, /shouldn't have been asked for its value 0 times, but was/)

      instance.value
      expect { did_not_ask :value, times: 1 }.to \
        raise_error(RSpec::Expectations::ExpectationNotMetError, /shouldn't have been asked for its value 1 time, but was/)
    end
  end

  describe 'conjunction of with(args) and times(n)' do
    before { mocked_class.define :value, default: nil }

    example 'default use case' do
      did_ask     :value, times: 0, with: [1, '2']
      did_not_ask :value, times: 1, with: [1, '2']
      instance.value
      did_ask     :value, times: 0, with: [1, '2']
      did_not_ask :value, times: 1, with: [1, '2']

      instance.value 1, '2'
      did_ask     :value, times: 1, with: [1, '2']
      instance.value 1, '2' # correct one
      instance.value 1, '3'
      instance.value 2, '2'
      instance.value 1, '2', 3
      instance.send positive_assertion, send(matcher_name, :value).times(2).with(1, '2')
      instance.send positive_assertion, send(matcher_name, :value).with(1, '2').times(2)
    end

    example 'failure message for should' do
      expect { did_ask :value, times: 1, with: [1, '2'] }.to \
        raise_error(RSpec::Expectations::ExpectationNotMetError, /should have been asked for its value 1 time with `1, "2"', but was never asked/)

      instance.value 1, '2'
      expect { did_ask :value, times: 0, with: [1, '2'] }.to \
        raise_error(RSpec::Expectations::ExpectationNotMetError, /should have been asked for its value 0 times with `1, "2"', but was asked 1 time/)

      instance.value 1, '2'
      expect { did_ask :value, times: 1, with: [1, '2'] }.to \
        raise_error(RSpec::Expectations::ExpectationNotMetError, /should have been asked for its value 1 time with `1, "2"', but was asked 2 times/)
    end

    example 'failure message for should not' do
      instance.value 1, '2'
      instance.value 1, '2'
      expect { did_not_ask :value, times: 2, with: [1, '2'] }.to \
        raise_error(RSpec::Expectations::ExpectationNotMetError, /should not have been asked for its value 2 times with `1, "2"'/)
    end
  end
end

describe 'should/should_not have_been_asked_for_its' do
  let(:positive_assertion) { :should }
  let(:negative_assertion) { :should_not }
  let(:matcher_name)       { :have_been_asked_for_its }

  it_behaves_like 'a noun matcher'
end

describe 'was/was_not asked_for' do
  let(:positive_assertion) { :was }
  let(:negative_assertion) { :was_not }
  let(:matcher_name)       { :asked_for }

  it_behaves_like 'a noun matcher'
end
