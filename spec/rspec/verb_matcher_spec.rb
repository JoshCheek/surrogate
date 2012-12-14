require 'spec_helper'

shared_examples_for 'a verb matcher' do

  let(:mocked_class) { Surrogate.endow Class.new }
  let(:instance) { mocked_class.new }

  def did(argument, modifiers={})
    assert!(positive_assertion, argument, modifiers)
  end

  def did_not(argument, modifiers={})
    assert!(negative_assertion, argument, modifiers)
  end

  def assert!(assertion, argument, modifiers)
    matcher = send(matcher_name, argument)
    matcher.send(:with, *modifiers[:with]) if modifiers.has_key? :with
    matcher.send(:times, modifiers[:times]) if modifiers.has_key? :times
    instance.send(assertion, matcher)
  end

  describe 'default use case' do
    before { mocked_class.define :kick, default: [] }

    example 'passes with a symbol if has been invoked at least once' do
      did_not :kick
      instance.kick
      did :kick
      instance.kick
      did :kick
    end

    example 'passes with a string if invoked at least once' do
      did_not "kick"
      instance.kick
      did "kick"
      instance.kick
      did "kick"
    end

    example 'failure message for should' do
      expect { did :kick }.to \
        raise_error(RSpec::Expectations::ExpectationNotMetError, /was never told to kick/)
    end

    example 'failure message for should not' do
      instance.kick
      expect { did_not :kick }.to \
        raise_error(RSpec::Expectations::ExpectationNotMetError, /shouldn't have been told to kick, but was told to kick 1 time/)

      instance.kick
      expect { did_not :kick }.to \
        raise_error(RSpec::Expectations::ExpectationNotMetError, /shouldn't have been told to kick, but was told to kick 2 times/)
    end
  end


  describe 'specifying which arguments it should have been invoked with' do
    before { mocked_class.define :smile, default: nil }

    example 'default use case' do
      did_not :smile, with: [1,2,3]
      instance.smile 1, 2
      did_not :smile, with: [1,2,3]
      instance.smile 1, 2, 3
      did :smile, with: [1,2,3]
    end

    example 'failure message for should' do
      expect { did :smile, with: [1,'2'] }.to \
        raise_error(RSpec::Expectations::ExpectationNotMetError, /should have been told to smile with `1, "2"', but was never told to/)

      instance.smile 3
      instance.smile 4, '5'
      expect { did :smile, with: [1,'2'] }.to \
        raise_error(RSpec::Expectations::ExpectationNotMetError, /should have been told to smile with `1, "2"', but got `3', `4, "5"'/)
    end

    example 'failure message for should not' do
      instance.smile 1, '2'
      expect { did_not :smile, with: [1,'2'] }.to \
        raise_error(RSpec::Expectations::ExpectationNotMetError, /should not have been told to smile with `1, "2"'/)
    end
  end


  describe 'specifying number of times invoked' do
    before { mocked_class.define :wink, default: nil }

    example 'default use case' do
      did :wink, times: 0
      instance.wink
      did :wink, times: 1
      instance.wink
      did :wink, times: 2
    end

    example 'failure message for should' do
      expect { did :wink, times: 1 }.to \
        raise_error(RSpec::Expectations::ExpectationNotMetError, /should have been told to wink 1 time but was told to wink 0 times/)

      instance.wink
      expect { did :wink, times: 2 }.to \
        raise_error(RSpec::Expectations::ExpectationNotMetError, /should have been told to wink 2 times but was told to wink 1 time/)
    end

    example 'failure message for should not' do
      expect { did_not :wink, times: 0 }.to \
        raise_error(RSpec::Expectations::ExpectationNotMetError, /shouldn't have been told to wink 0 times, but was/)

      instance.wink
      expect { did_not :wink, times: 1 }.to \
        raise_error(RSpec::Expectations::ExpectationNotMetError, /shouldn't have been told to wink 1 time, but was/)
    end
  end

  describe 'conjunction of with(args) and times(n)' do
    before { mocked_class.define :wink, default: nil }

    example 'default use case' do
      did     :wink, times: 0, with: [1, '2']
      did_not :wink, times: 1, with: [1, '2']
      instance.wink
      did     :wink, times: 0, with: [1, '2']
      did_not :wink, times: 1, with: [1, '2']
      instance.wink 1, '2'
      did     :wink, times: 1, with: [1, '2']
      instance.wink 1, '2' # correct one
      instance.wink 1, '3'
      instance.wink 2, '2'
      instance.wink 1, '2', 3
      instance.send positive_assertion, send(matcher_name, :wink).times(2).with(1, '2')
      instance.send positive_assertion, send(matcher_name, :wink).with(1, '2').times(2)
    end

    example 'failure message for should' do
      expect { did :wink, times: 1, with: [1, '2'] }.to \
        raise_error(RSpec::Expectations::ExpectationNotMetError, /should have been told to wink 1 time with `1, "2"', but was never told to/)

      instance.wink 1, '2'
      expect { did :wink, times: 0, with: [1, '2'] }.to \
        raise_error(RSpec::Expectations::ExpectationNotMetError, /should have been told to wink 0 times with `1, "2"', but got it 1 time/)

      instance.wink 1, '2'
      expect { did :wink, times: 1, with: [1, '2'] }.to \
        raise_error(RSpec::Expectations::ExpectationNotMetError, /should have been told to wink 1 time with `1, "2"', but got it 2 times/)
    end

    example 'failure message for should not' do
      instance.wink 1, '2'
      instance.wink 1, '2'
      expect { did_not :wink, times: 2, with: [1, '2'] }.to \
        raise_error(RSpec::Expectations::ExpectationNotMetError, /should not have been told to wink 2 times with `1, "2"'/)
    end
  end
end


describe 'should/should_not have_been_told_to' do
  let(:positive_assertion) { :should }
  let(:negative_assertion) { :should_not }
  let(:matcher_name)       { :have_been_told_to }

  it_behaves_like 'a verb matcher'
end

describe 'was/was_not told_to' do
  let(:positive_assertion) { :was }
  let(:negative_assertion) { :was_not }
  let(:matcher_name)       { :told_to }

  it_behaves_like 'a verb matcher'
end
