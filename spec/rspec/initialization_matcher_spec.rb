require 'spec_helper'

describe 'should/should_not have_been_initialized_with' do
  let(:mocked_class) { Surrogate.endow(Class.new).define(:initialize) { |*| } }

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

  example "informs you when it wasn't defined" do
    expect { Surrogate.endow(Class.new).new.should have_been_initialized_with no_args }
      .to raise_error Surrogate::UnknownMethod
  end
end

describe 'was/was_not initialized_with' do
  let(:mocked_class) { Surrogate.endow(Class.new).define(:initialize) { |*| } }

  it 'is the same as have_been_told_to(:initialize).with(...)' do
    mocked_class.new.was initialized_with no_args
    mocked_class.new.was_not initialized_with 1
    mocked_class.new(1).was initialized_with 1
    mocked_class.new(1, '2').was initialized_with 1, '2'
  end

  def failure_message_for
    yield
  rescue RSpec::Expectations::ExpectationNotMetError
    $!.message
  end

  example 'failure message for should' do
    failure_message_for { mocked_class.new("1").was initialized_with 2 }.should ==
      failure_message_for { mocked_class.new("1").was told_to(:initialize).with(2) }
  end

  example 'failure message for should not' do
    failure_message_for { mocked_class.new("1").was_not initialized_with('1') }.should ==
      failure_message_for { mocked_class.new("1").was_not told_to(:initialize).with('1') }
  end

  example "informs you when it wasn't defined" do
    expect { Surrogate.endow(Class.new).new.was initialized_with no_args }
      .to raise_error Surrogate::UnknownMethod
  end
end
