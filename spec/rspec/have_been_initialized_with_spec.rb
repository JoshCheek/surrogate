require 'spec_helper'

describe 'RSpec matchers', 'have_been_initialized_with' do
  let(:mocked_class) { Surrogate.endow Class.new }
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
