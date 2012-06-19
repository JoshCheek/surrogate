class Surrogate
  module RSpec
    class InvocationMatcher
      attr_accessor :times_predicate, :with_filter, :surrogate, :method_name

      def initialize(method_name)
        self.method_name     = method_name
        self.times_predicate = TimesPredicate.new
        self.with_filter     = WithFilter.new
      end

      def matches?(surrogate)
        self.surrogate = surrogate
        times_predicate.matches? filtered_args
      end

      def filtered_args
        @filtered_args ||= with_filter.filter invocations
      end

      def invocations
        surrogate.invocations(method_name)
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
        FailureMessages.new(with_filter, times_predicate)
                       .messages(message_category, method_name, invocations, self.class::MESSAGES)
      end
    end
  end
end
