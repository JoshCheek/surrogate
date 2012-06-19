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

        def inspect_arguments(args)
          @env.inspect_arguments args
        end

        def expected_arguments
          @env.expected_arguments
        end

        def actual_invocation
          @env.actual_invocation
        end

        def times_msg(num)
          @env.times_msg num
        end

        def invocations
          @env.invocations
        end

        def expected_times_invoked
          @env.expected_times_invoked
        end
      end


      class FailureMessageShouldDefault < FailureMessageInternal
        def get_message
          "was never told to #{ method_name }"
        end
      end

      class FailureMessageShouldWith < FailureMessageInternal
        def get_message
          "should have been told to #{ method_name } with #{ inspect_arguments expected_arguments }, but #{ actual_invocation }"
        end
      end

      class FailureMessageShouldTimes < FailureMessageInternal
        def get_message
          "should have been told to #{ method_name } #{ times_msg expected_times_invoked } but was told to #{ method_name } #{ times_msg invocations.size }"
        end
      end

      class FailureMessageWithTimes < FailureMessageInternal
        def get_message
          "should have been told to #{ method_name } #{ times_msg expected_times_invoked } with #{ inspect_arguments expected_arguments }, but #{ actual_invocation }"
        end
      end

      class FailureMessageShouldNotDefault < FailureMessageInternal
        def get_message
          "shouldn't have been told to #{ method_name }, but was told to #{ method_name } #{ times_msg invocations.size }"
        end
      end

      MESSAGES = {
        should: {
          default:    FailureMessageShouldDefault.new,
          with:       FailureMessageShouldWith.new,
          times:      FailureMessageShouldTimes.new,
          with_times: FailureMessageWithTimes.new,
          },
        should_not: {
          default:    FailureMessageShouldNotDefault.new,
          with:       FailureMessageBlock.new { "should not have been told to #{ method_name } with #{ inspect_arguments expected_arguments }, but #{ actual_invocation }" },
          times:      FailureMessageBlock.new { "shouldn't have been told to #{ method_name } #{ times_msg expected_times_invoked }, but was" },
          with_times: FailureMessageBlock.new { "should not have been told to #{ method_name } #{ times_msg expected_times_invoked } with #{ inspect_arguments expected_arguments }, but #{ actual_invocation }" },
        },
      }
    end
  end
end
