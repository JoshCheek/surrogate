require 'surrogate/rspec/invocation_matcher'

class Surrogate
  module RSpec
    class HaveBeenToldTo < InvocationMatcher

      class FailureMessageShouldDefault < AbstractFailureMessage
        def get_message
          "was never told to #{ method_name }"
        end
      end


      class FailureMessageShouldWith < AbstractFailureMessage
        def get_message
          message = "should have been told to #{ method_name } with #{ inspect_arguments expected_arguments }, but "
          if times_invoked.zero?
            message << "was never told to"
          else
            inspected_invocations = invocations.map { |invocation| inspect_arguments invocation }
            message << "got #{inspected_invocations.join ', '}"
          end
        end
      end


      class FailureMessageShouldTimes < AbstractFailureMessage
        def get_message
          "should have been told to #{ method_name } #{ times_msg expected_times_invoked } but was told to #{ method_name } #{ times_msg times_invoked }"
        end
      end


      class FailureMessageWithTimes < AbstractFailureMessage
        def get_message
          message = "should have been told to #{ method_name } #{ times_msg expected_times_invoked } with #{ inspect_arguments expected_arguments }, but "
          if times_invoked.zero?
            message << "was never told to"
          else
            message << "got it #{times_msg times_invoked_with_expected_args}"
          end
        end
      end


      class FailureMessageShouldNotDefault < AbstractFailureMessage
        def get_message
          "shouldn't have been told to #{ method_name }, but was told to #{ method_name } #{ times_msg times_invoked }"
        end
      end


      class FailureMessageShouldNotWith < AbstractFailureMessage
        def get_message
          message = "should not have been told to #{ method_name } with #{ inspect_arguments expected_arguments }, but "
          if times_invoked.zero?
            message << "was never told to"
          else
            inspected_invocations = invocations.map { |invocation| inspect_arguments invocation }
            message << "got #{inspected_invocations.join ', '}"
          end
        end
      end


      class FailureMessageShouldNotTimes < AbstractFailureMessage
        def get_message
          "shouldn't have been told to #{ method_name } #{ times_msg expected_times_invoked }, but was"
        end
      end


      class FailureMessageShouldNotWithTimes < AbstractFailureMessage
        def get_message
          message = "should not have been told to #{ method_name } #{ times_msg expected_times_invoked } with #{ inspect_arguments expected_arguments }, but "
          if times_invoked.zero?
             message << "was never told to"
          else
            message << "got it #{times_msg times_invoked_with_expected_args}"
          end
        end
      end


      def failure_message_for_should
        message_class =
            if times_predicate.default? && with_filter.default?
              FailureMessageShouldDefault
            elsif times_predicate.default?
              FailureMessageShouldWith
            elsif with_filter.default?
              FailureMessageShouldTimes
            else
              FailureMessageWithTimes
            end
        message_class.new(method_name, invocations, with_filter, times_predicate).get_message
      end

      def failure_message_for_should_not
        message_class =
            if times_predicate.default? && with_filter.default?
              FailureMessageShouldNotDefault
            elsif times_predicate.default?
              FailureMessageShouldNotWith
            elsif with_filter.default?
              FailureMessageShouldNotTimes
            else
              FailureMessageShouldNotWithTimes
            end
        message_class.new(method_name, invocations, with_filter, times_predicate).get_message
      end
    end
  end
end
