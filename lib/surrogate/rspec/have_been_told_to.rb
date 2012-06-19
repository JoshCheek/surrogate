require 'surrogate/rspec/invocation_matcher'

class Surrogate
  module RSpec
    class HaveBeenToldTo < InvocationMatcher
      class FailureMessage
        def initialize(&message)
          @message = message
        end

        def result(env)
          env.instance_eval &@message
        end
      end

      MESSAGES = {
        should: {
          default:    FailureMessage.new { "was never told to #{ method_name }" },
          with:       FailureMessage.new { "should have been told to #{ method_name } with #{ inspect_arguments expected_arguments }, but #{ actual_invocation }" },
          times:      FailureMessage.new { "should have been told to #{ method_name } #{ times_msg expected_times_invoked } but was told to #{ method_name } #{ times_msg invocations.size }" },
          with_times: FailureMessage.new { "should have been told to #{ method_name } #{ times_msg expected_times_invoked } with #{ inspect_arguments expected_arguments }, but #{ actual_invocation }" },
          },
        should_not: {
          default:    FailureMessage.new { "shouldn't have been told to #{ method_name }, but was told to #{ method_name } #{ times_msg invocations.size }" },
          with:       FailureMessage.new { "should not have been told to #{ method_name } with #{ inspect_arguments expected_arguments }, but #{ actual_invocation }" },
          times:      FailureMessage.new { "shouldn't have been told to #{ method_name } #{ times_msg expected_times_invoked }, but was" },
          with_times: FailureMessage.new { "should not have been told to #{ method_name } #{ times_msg expected_times_invoked } with #{ inspect_arguments expected_arguments }, but #{ actual_invocation }" },
        },
      }
    end
  end
end
