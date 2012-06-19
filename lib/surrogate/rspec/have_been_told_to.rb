require 'surrogate/rspec/invocation_matcher'

class Surrogate
  module RSpec
    class HaveBeenToldTo < InvocationMatcher
      class FailureMessageBlock
        def initialize(&message)
          @message = message
        end

        def result(env)
          env.instance_eval &@message
        end
      end

      class FailureMessageInternal
        def result(env)
          @env = env
          get_message
        end

        def get_message
          raise "I should have been overridden"
        end

        def method_name
          @env.method_name
        end
      end

      class FailureMessageShouldDefault < FailureMessageInternal
        def get_message
          "was never told to #{ method_name }"
        end
      end

      MESSAGES = {
        should: {
          default:    FailureMessageShouldDefault.new,
          with:       FailureMessageBlock.new { "should have been told to #{ method_name } with #{ inspect_arguments expected_arguments }, but #{ actual_invocation }" },
          times:      FailureMessageBlock.new { "should have been told to #{ method_name } #{ times_msg expected_times_invoked } but was told to #{ method_name } #{ times_msg invocations.size }" },
          with_times: FailureMessageBlock.new { "should have been told to #{ method_name } #{ times_msg expected_times_invoked } with #{ inspect_arguments expected_arguments }, but #{ actual_invocation }" },
          },
        should_not: {
          default:    FailureMessageBlock.new { "shouldn't have been told to #{ method_name }, but was told to #{ method_name } #{ times_msg invocations.size }" },
          with:       FailureMessageBlock.new { "should not have been told to #{ method_name } with #{ inspect_arguments expected_arguments }, but #{ actual_invocation }" },
          times:      FailureMessageBlock.new { "shouldn't have been told to #{ method_name } #{ times_msg expected_times_invoked }, but was" },
          with_times: FailureMessageBlock.new { "should not have been told to #{ method_name } #{ times_msg expected_times_invoked } with #{ inspect_arguments expected_arguments }, but #{ actual_invocation }" },
        },
      }
    end
  end
end
