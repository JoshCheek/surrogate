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



    class AbstractFailureMessage
      attr_accessor :method_name, :invocations, :with_filter, :times_predicate

      def initialize(method_name, invocations, with_filter, times_predicate)
        self.method_name     = method_name
        self.invocations     = invocations
        self.with_filter     = with_filter
        self.times_predicate = times_predicate
      end

      def get_message
        raise "I should have been overridden"
      end

      def times_invoked
        invocations.size
      end

      # can we extract out an args inspecter?
      def inspect_arguments(arguments)
        inspected_arguments = arguments.map { |argument| inspect_argument argument }
        inspected_arguments << 'no args' if inspected_arguments.empty?
        "`" << inspected_arguments.join(", ") << "'"
      end

      def inspect_argument(to_inspect)
        if RSpec.rspec_mocks_loaded? && to_inspect.respond_to?(:description)
          to_inspect.description
        else
          to_inspect.inspect
        end
      end

      def expected_arguments
        with_filter.args
      end

      def times_msg(n)
        "#{n} time#{'s' unless n == 1}"
      end

      def expected_times_invoked
        times_predicate.expected_times_invoked
      end

      def times_invoked_with_expected_args
        invocations.size
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
        raise "THIS METHOD SHOULD HAVE BEEN OVERRIDDEN"
      end

      def failure_message_for_should_not
        raise "THIS METHOD SHOULD HAVE BEEN OVERRIDDEN"
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
    end
  end
end
