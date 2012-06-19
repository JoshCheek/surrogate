class Surrogate
  module RSpec
    class HaveBeenToldTo
      attr_reader :handler
      attr_accessor :times_predicate, :with_filter

      attr_accessor :instance, :subject
      attr_accessor :expected_times_invoked, :expected_arguments

      def initialize(expected)
        self.subject = expected
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
        instance.invocations(subject)
      end

      def failure_message_for_should
        message_for :should
      end

      def failure_message_for_should_not
        message_for :should_not
      end

      def times(times_invoked)
        @times_predicate = TimesPredicate.new(times_invoked, :==)
        self.expected_times_invoked = times_invoked
        self
      end

      def with(*arguments, &expectation_block)
        self.with_filter = WithFilter.new arguments, :args_must_match,  &expectation_block
        arguments << expectation_block if expectation_block
        self.expected_arguments = arguments
        self
      end

      def message_for(message_category)
        FailureMessages.new.messages(message_category, with_filter, times_predicate, subject, invocations)
      end
    end
  end
end
