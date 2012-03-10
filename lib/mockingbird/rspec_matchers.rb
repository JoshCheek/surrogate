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
    "shouldn't have been told to #{verb}, but was told to #{verb} #{times_msg times_invoked}"
  end

  def times_msg(n)
    "#{n} time#{'s' unless n == 1}"
  end
end


with_arguments = Module.new do
  attr_accessor :expected_arguments
  
  def match?
    invocations.include? expected_arguments
  end

  def failure_message_for_should
    "should have been told to #{verb} with `#{expected_arguments.map(&:inspect).join ', '}'"
  end

  def failure_message_for_should_not
    failure_message_for_should.sub "should", "should not"
  end
end


match_num_times = Module.new do
  attr_accessor :expected_times_invoked
  def match?
    expected_times_invoked == times_invoked
  end

  def failure_message_for_should
    "should have been told to #{verb} #{times_msg expected_times_invoked} but was told to #{verb} #{times_msg times_invoked}"
  end

  def failure_message_for_should_not
    "shouldn't have been told to #{verb} #{times_msg expected_times_invoked}, but was"
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

  chain :with do |*arguments|
    use_case.extend with_arguments
    use_case.expected_arguments = arguments
  end

  failure_message_for_should     { use_case.failure_message_for_should }
  failure_message_for_should_not { use_case.failure_message_for_should_not }
  description                    { "Assert the object was told to do something" }
end


