require 'spec_helper'

shared_examples_for 'a predicate matcher' do
  let(:mocked_class) { Surrogate.endow(Class.new).define :changed?, default: false }
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
    example 'passes if has been invoked at least once' do
      did_not_ask :changed?
      instance.changed?
      did_ask :changed?
      instance.changed?
      did_ask :changed?
    end

    example 'failure message for should' do
      expect { did_ask :changed? }.to \
        raise_error(RSpec::Expectations::ExpectationNotMetError, /was never asked if changed?/)
    end

    example 'failure message for should not' do
      instance.changed?
      expect { did_not_ask :changed? }.to \
        raise_error(RSpec::Expectations::ExpectationNotMetError, /shouldn't have been asked if changed\?, but was asked 1 time/)

      instance.changed?
      expect { did_not_ask :changed? }.to \
        raise_error(RSpec::Expectations::ExpectationNotMetError, /shouldn't have been asked if changed\?, but was asked 2 times/)
    end
  end


  describe 'specifying which arguments it should have been invoked with' do

    example 'default use case' do
      did_not_ask :changed?, with: [1, 2, 3]
      instance.changed? 1, 2
      did_not_ask :changed?, with: [1, 2, 3]
      instance.changed? 1, 2, 3
      did_ask :changed?, with: [1, 2, 3]
    end

    example 'failure message for should' do
      expect { did_ask :changed?, with: [1, '2'] }.to \
        raise_error(RSpec::Expectations::ExpectationNotMetError, /should have been asked if changed\? with `1, "2"', but was never asked/)

      instance.changed? 3
      instance.changed? 4, '5'
      expect { did_ask :changed?, with: [1, '2'] }.to \
        raise_error(RSpec::Expectations::ExpectationNotMetError, /should have been asked if changed\? with `1, "2"', but got `3', `4, "5"'/)
    end

    example 'failure message for should not' do
      instance.changed? 1, '2'
      expect { did_not_ask :changed?, with: [1, '2'] }.to \
        raise_error(RSpec::Expectations::ExpectationNotMetError, /should not have been asked if changed\? with `1, "2"'/)
    end

    describe 'integration with rspec argument_matchers' do
      it 'works with rspec matchers' do
        did_not_ask :changed?, with: [no_args]
        instance.changed?(1)
        did_not_ask :changed?, with: [no_args]
        instance.changed?
        did_ask     :changed?, with: [no_args]

        did_not_ask :changed?, with: [hash_including(all: true)]
        instance.changed? any: false, all: true
        did_ask     :changed?, with: [hash_including(all: true)]
        did_not_ask :changed?, with: [hash_including(all: false)]
      end
    end
  end


  describe 'specifying number of times invoked' do

    example 'default use case' do
      did_ask :changed?, times: 0
      instance.changed?
      did_ask :changed?, times: 1
      instance.changed?
      did_ask :changed?, times: 2
    end

    example 'failure message for should' do
      expect { did_ask :changed?, times: 1 }.to \
        raise_error(RSpec::Expectations::ExpectationNotMetError, /should have been asked if changed\? 1 time, but was asked 0 times/)

      instance.changed?
      expect { did_ask :changed?, times: 2 }.to \
        raise_error(RSpec::Expectations::ExpectationNotMetError, /should have been asked if changed\? 2 times, but was asked 1 time/)
    end

    example 'failure message for should not' do
      expect { did_not_ask :changed?, times: 0 }.to \
        raise_error(RSpec::Expectations::ExpectationNotMetError, /shouldn't have been asked if changed\? 0 times, but was/)

      instance.changed?
      expect { did_not_ask :changed?, times: 1 }.to \
        raise_error(RSpec::Expectations::ExpectationNotMetError, /shouldn't have been asked if changed\? 1 time, but was/)
    end
  end

  describe 'conjunction of with(args) and times(n)' do

    example 'default use case' do
      did_ask     :changed?, times: 0, with: [1, '2']
      did_not_ask :changed?, times: 1, with: [1, '2']
      instance.changed?
      did_ask     :changed?, times: 0, with: [1, '2']
      did_not_ask :changed?, times: 1, with: [1, '2']
      instance.changed? 1, '2'
      did_ask     :changed?, times: 1, with: [1, '2']
      instance.changed? 1, '2' # correct one
      instance.changed? 1, '3'
      instance.changed? 2, '2'
      instance.changed? 1, '2', 3
      instance.send positive_assertion, send(matcher_name, :changed?).times(2).with(1, '2')
      instance.send positive_assertion, send(matcher_name, :changed?).with(1, '2').times(2)
    end

    example 'failure message for should' do
      expect { did_ask :changed?, times: 1, with: [1, '2'] }.to \
        raise_error(RSpec::Expectations::ExpectationNotMetError, /should have been asked if changed\? 1 time with `1, "2"', but was never asked/)

      instance.changed? 1, '2'
      expect { did_ask :changed?, times: 0, with: [1, '2'] }.to \
        raise_error(RSpec::Expectations::ExpectationNotMetError, /should have been asked if changed\? 0 times with `1, "2"', but was asked 1 time/)

      instance.changed? 1, '2'
      expect { did_ask :changed?, times: 1, with: [1, '2'] }.to \
        raise_error(RSpec::Expectations::ExpectationNotMetError, /should have been asked if changed\? 1 time with `1, "2"', but was asked 2 times/)
    end

    example 'failure message for should not' do
      instance.changed? 1, '2'
      instance.changed? 1, '2'
      expect { did_not_ask :changed?, times: 2, with: [1, '2'] }.to \
        raise_error(RSpec::Expectations::ExpectationNotMetError, /should not have been asked if changed\? 2 times with `1, "2"'/)
    end
  end
end

describe 'should/should_not have_been_asked_if' do
  let(:positive_assertion) { :should }
  let(:negative_assertion) { :should_not }
  let(:matcher_name)       { :have_been_asked_if }

  it_behaves_like 'a predicate matcher'
end

describe 'was/was_not asked_if' do
  let(:positive_assertion) { :was }
  let(:negative_assertion) { :was_not }
  let(:matcher_name)       { :asked_if }

  it_behaves_like 'a predicate matcher'
end

