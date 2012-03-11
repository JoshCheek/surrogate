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
    "should have been told to #{verb} with `#{expected_arguments.map(&:inspect).join ', '}', but #{actual_invocation}"
  end

  def actual_invocation
    return "was never invoked" if times_invoked.zero?
    inspected_invocations = invocations.map { |invocation| "`#{invocation.map(&:inspect).join ', '}'" }
    "got #{inspected_invocations.join ', '}"
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


match_num_times_with = Module.new do
  attr_accessor :expected_times_invoked, :expected_arguments

  def times_invoked_with_expected_args
    invocations.select { |invocation| invocation == expected_arguments }.size
  end

  def match?
    times_invoked_with_expected_args == expected_times_invoked
  end

  def failure_message_for_should
    "should have been told to #{verb} #{times_msg expected_times_invoked} with " \
      "`#{expected_arguments.map(&:inspect).join ', '}', but #{actual_invocation}"
  end

  def failure_message_for_should_not
    failure_message_for_should.sub "should", "should not"
  end

  def actual_invocation
    return "was never told to" if times_invoked.zero?
    "got it #{times_msg times_invoked_with_expected_args}"
  end
end


RSpec::Matchers.define :have_been_told_to do |verb|
  use_case = handler.new verb

  match do |mocked_instance|
    use_case.instance = mocked_instance
    use_case.match?
  end

  chain :times do |number|
    use_case.extend (use_case.kind_of?(with_arguments) ? match_num_times_with : match_num_times)
    use_case.expected_times_invoked = number
  end

  chain :with do |*arguments|
    use_case.extend (use_case.kind_of?(match_num_times) ? match_num_times_with : with_arguments)
    use_case.expected_arguments = arguments
  end

  failure_message_for_should     { use_case.failure_message_for_should }
  failure_message_for_should_not { use_case.failure_message_for_should_not }
  description                    { "Assert the object was told to do something" }
end


