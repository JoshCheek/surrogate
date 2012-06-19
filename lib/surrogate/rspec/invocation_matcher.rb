class Surrogate
  module RSpec


    class TimesPredicate
      attr_accessor :expected_times_invoked, :comparer
      def initialize(expected_times_invoked=0, comparer=:<)
        self.expected_times_invoked = expected_times_invoked
        self.comparer = comparer
      end

      def matches?(invocations)
        expected_times_invoked.send comparer, invocations.size
      end

      def default?
        expected_times_invoked == 0 && comparer == :<
      end
    end



    class WithFilter
      attr_accessor :args, :block, :pass, :filter_name

      def initialize(args=[], filter_name=:default_filter, &block)
        self.args = args
        self.block = block
        self.pass = send filter_name
        self.filter_name = filter_name
      end

      def filter(invocations)
        invocations.select &pass
      end

      def default?
        filter_name == :default_filter
      end

      private

      def default_filter
        Proc.new { true }
      end

      def args_must_match
        lambda { |invocation| args_match? args, invocation }
      end

      def args_match?(expected_arguments, actual_arguments)
        if expected_arguments.last.kind_of? Proc
          return unless actual_arguments.last.kind_of? Proc
          block_that_tests = expected_arguments.last
          block_to_test = actual_arguments.last
          asserter = Handler::BlockAsserter.new(block_to_test)
          block_that_tests.call asserter
          asserter.match?
        else
          if RSpec.rspec_mocks_loaded?
            rspec_arg_expectation = ::RSpec::Mocks::ArgumentExpectation.new *expected_arguments
            rspec_arg_expectation.args_match? *actual_arguments
          else
            expected_arguments == actual_arguments
          end
        end
      end
    end



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
        FailureMessages.new(method_name, invocations, with_filter, times_predicate, self.class::MESSAGES, message_category).message
      end
    end
  end
end
