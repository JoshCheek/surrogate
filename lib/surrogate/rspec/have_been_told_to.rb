class Surrogate
  module RSpec
    class HaveBeenToldTo
      MESSAGES = {
        should: {
          default:    "was never told to <%= method_name %>",
          with:       "should have been told to <%= method_name %> with <%= inspect_arguments expected_arguments %>, but <%= actual_invocation %>",
          times:      "should have been told to <%= method_name %> <%= times_msg expected_times_invoked %> but was told to <%= method_name %> <%= times_msg invocations.size %>",
          with_times: "should have been told to <%= method_name %> <%= times_msg expected_times_invoked %> with <%= inspect_arguments expected_arguments %>, but <%= actual_invocation %>",
          },
        should_not: {
          default:    "shouldn't have been told to <%= method_name %>, but was told to <%= method_name %> <%= times_msg invocations.size %>",
          with:       "should not have been told to <%= method_name %> with <%= inspect_arguments expected_arguments %>, but <%= actual_invocation %>",
          times:      "shouldn't have been told to <%= method_name %> <%= times_msg expected_times_invoked %>, but was",
          with_times: "should not have been told to <%= method_name %> <%= times_msg expected_times_invoked %> with <%= inspect_arguments expected_arguments %>, but <%= actual_invocation %>",
        },
      }

      attr_accessor :times_predicate, :with_filter
      attr_accessor :instance, :method_name

      def initialize(method_name)
        self.method_name = method_name
        self.times_predicate = TimesPredicate.new
        self.with_filter = WithFilter.new
      end

      def matches?(mocked_instance)
        self.instance = mocked_instance
        times_predicate.matches? filtered_args
      end

      def filtered_args
        @filtered_args ||= with_filter.filter invocations
      end

      def invocations
        instance.invocations(method_name)
      end

      def failure_message_for_should
        message_for :should
      end

      def failure_message_for_should_not
        message_for :should_not
      end

      def times(times_invoked)
        @times_predicate = TimesPredicate.new(times_invoked, :==)
        self
      end

      def with(*arguments, &expectation_block)
        self.with_filter = WithFilter.new arguments, :args_must_match,  &expectation_block
        arguments << expectation_block if expectation_block
        self
      end

      def message_for(message_category)
        FailureMessages.new.messages(message_category, with_filter, times_predicate, method_name, invocations, MESSAGES)
      end
    end
  end
end
