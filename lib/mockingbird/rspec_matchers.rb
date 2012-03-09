RSpec::Matchers.define :have_been_told_to do |verb|
  invocations = nil
  match do |mocked_instance|
    invocations = mocked_instance.invocations(verb)
    if @n_times
      invocations.size == @n_times
    else
      !invocations.empty?
    end
  end

  chain :times do |number|
    @n_times = number
  end

  failure_message_for_should do |actual|
    invocations.inspect
    # "#{actual.invocation(verb).inspect} should have included #{arg.inspect} "
  end

  failure_message_for_should_not do |actual|
    invocations.inspect
    # "should not have been #{arg.inspect}, but was #{actual.inspect}"
  end

  description do
    "Assert the object was told to do something"
  end
end


