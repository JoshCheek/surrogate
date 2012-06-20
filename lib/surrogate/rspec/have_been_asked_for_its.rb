require 'surrogate/rspec/invocation_matcher'

class Surrogate
  module RSpec
    class HaveBeenAskedForIts < InvocationMatcher

      class FailureMessageShouldDefault < AbstractFailureMessage
        def get_message
          "was never asked for its #{ method_name }"
        end
      end

      class FailureMessageShouldWith < AbstractFailureMessage
        def get_message
          message = "should have been asked for its #{ method_name } with #{ inspect_arguments expected_invocation }, but "
          if times_invoked.zero?
            message << "was never asked"
          else
            inspected_invocations = invocations.map { |invocation| inspect_arguments invocation }
            message << "got #{inspected_invocations.join ', '}"
          end
        end
      end

      class FailureMessageShouldTimes < AbstractFailureMessage
        def get_message
          "should have been asked for its #{ method_name } #{ times_msg expected_times_invoked }, but was asked #{ times_msg times_invoked }"
        end
      end

      class FailureMessageWithTimes < AbstractFailureMessage
        def get_message
          message = "should have been asked for its #{ method_name } #{ times_msg expected_times_invoked } with #{ inspect_arguments expected_invocation }, but "
          if times_invoked.zero?
            message << "was never asked"
          else
            message << "was asked #{times_msg times_invoked}"
          end
        end
      end

      class FailureMessageShouldNotDefault < AbstractFailureMessage
        def get_message
          "shouldn't have been asked for its #{ method_name }, but was asked #{ times_msg times_invoked }"
        end
      end

      class FailureMessageShouldNotWith < AbstractFailureMessage
        def get_message
          message = "should not have been asked for its #{ method_name } with #{ inspect_arguments expected_invocation }, but "
          if times_invoked.zero?
            message << "was never asked"
          else
            inspected_invocations = invocations.map { |invocation| inspect_arguments invocation }
            message << "got #{inspected_invocations.join ', '}"
          end
        end
      end

      class FailureMessageShouldNotTimes < AbstractFailureMessage
        def get_message
          "shouldn't have been asked for its #{ method_name } #{ times_msg expected_times_invoked }, but was"
        end
      end

      class FailureMessageShouldNotWithTimes < AbstractFailureMessage
        def get_message
          message = "should not have been asked for its #{ method_name } #{ times_msg expected_times_invoked } with #{ inspect_arguments expected_invocation }, "
          if times_invoked.zero?
             message << "was never asked"
          else
            message << "was asked #{times_msg times_invoked}"
          end
        end
      end
    end
  end
end
