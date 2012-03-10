handler = Struct.new :verb, :instance do
  def invocations
    instance.invocations(verb)
  end

  def times_invoked
    invocations.size
  end

  def match?
    times_invoked > 0
  end

  def failure_message_for_should
    "was never told to #{verb}"
  end

  def failure_message_for_should_not
    time_or_times = times_invoked > 1 ? 'times' : 'time'
    "shouldn't have been told to #{verb}, but was told to #{verb} #{times_invoked} #{time_or_times}"
  end
end


match_num_times = Module.new do
  attr_accessor :expected_times_invoked
  def match?
    expected_times_invoked == times_invoked
  end

  def failure_message_for_should
    "should have been told to wink #{expected_times_invoked} " \
    "time#{'s' if expected_times_invoked != 1} but was told to wink " \
    "#{times_invoked} time#{'s' if times_invoked != 1}"
  end

  def failure_message_for_should_not
    "shouldn't have been told to wink #{expected_times_invoked} " \
      "time#{'s' if expected_times_invoked != 1}, but was"
  end
end


RSpec::Matchers.define :have_been_told_to do |verb|
  use_case = handler.new verb

  match do |mocked_instance|
    use_case.instance = mocked_instance
    use_case.match?
  end

  chain :times do |number|
    use_case.extend match_num_times
    use_case.expected_times_invoked = number
  end

  failure_message_for_should do
    use_case.failure_message_for_should
  end

  failure_message_for_should_not do |actual|
    use_case.failure_message_for_should_not
  end

  description do
    "Assert the object was told to do something"
  end
end


