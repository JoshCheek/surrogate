require 'surrogate/rspec/invocation_matcher'

class Surrogate
  module RSpec
    class HaveBeenToldTo < InvocationMatcher
      class Message
        def initialize(erb_message=nil, &message)
          @message = message || erb_message
          @is_erb = erb_message
        end

        def erb?
          @is_erb
        end

        def result(env)
          @env = env
          if erb?
            ERB.new(@message).result(binding)
          else
            @env.instance_eval &@message
          end
        end

        def method_missing(*args, &block)
          @env.send(*args, &block)
        end
      end

      MESSAGES = {
        should: {
          default:    Message.new { "was never told to #{ method_name }" },
          with:       Message.new { "should have been told to #{ method_name } with #{ inspect_arguments expected_arguments }, but #{ actual_invocation }" },
          times:      Message.new { "should have been told to #{ method_name } #{ times_msg expected_times_invoked } but was told to #{ method_name } #{ times_msg invocations.size }" },
          with_times: Message.new { "should have been told to #{ method_name } #{ times_msg expected_times_invoked } with #{ inspect_arguments expected_arguments }, but #{ actual_invocation }" },
          },
        should_not: {
          default:    Message.new { "shouldn't have been told to #{ method_name }, but was told to #{ method_name } #{ times_msg invocations.size }" },
          with:       Message.new { "should not have been told to #{ method_name } with #{ inspect_arguments expected_arguments }, but #{ actual_invocation }" },
          times:      Message.new { "shouldn't have been told to #{ method_name } #{ times_msg expected_times_invoked }, but was" },
          with_times: Message.new { "should not have been told to #{ method_name } #{ times_msg expected_times_invoked } with #{ inspect_arguments expected_arguments }, but #{ actual_invocation }" },
        },
      }
    end
  end
end
