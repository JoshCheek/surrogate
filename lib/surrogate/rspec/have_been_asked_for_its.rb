class Surrogate
  module RSpec
    class HaveBeenAskedForIts
      class TimesPredicate
        attr_accessor :expected_times_invoked, :comparer

        def initialize(expected_times_invoked, comparer)
          self.expected_times_invoked = expected_times_invoked
          self.comparer = comparer
        end

        def matches?(invocations)
          expected_times_invoked.send comparer, invocations.size
        end
      end

      class WithFilter
        attr_accessor :args, :block, :pass

        def initialize(args=[], filter_name=:default_filter, &block)
          self.args = args
          self.block = block
          self.pass = send filter_name
          @filter_name = filter_name
        end

        def filter(invocations)
          invocations.select &pass
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
            block_asserter = lambda { |invocation|
              return unless invocation.last.kind_of? Proc
              block_that_tests = expected_arguments.last
              block_to_test = invocation.last
              asserter = Handler::BlockAsserter.new(block_to_test)
              block_that_tests.call asserter
            asserter.match?
            }
            times_predicate.matches?(invocations.select { |invocation| block_asserter[invocation] })
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

      attr_reader :handler
      attr_accessor :times_predicate, :with_filter

      attr_accessor :instance, :subject, :message_type
      attr_accessor :expected_times_invoked, :expected_arguments

      # keep
      def initialize(expected)
        self.subject = expected
        self.message_type = :default
        self.times_predicate = TimesPredicate.new(0, :<)
        self.with_filter = WithFilter.new
      end

      # keep
      def matches?(mocked_instance)
        self.instance = mocked_instance
        times_predicate.matches? with_filter.filter invocations
      end

      # keep
      def invocations
        instance.invocations(subject)
      end

      # keep
      def failure_message_for_should
        message_for :should, message_type
      end

      # keep
      def failure_message_for_should_not
        message_for :should_not, message_type
      end

      # keep (refactor me)
      def times(times_invoked)
        @times_predicate = TimesPredicate.new(times_invoked, :==)

        if message_type == :with
          self.message_type = :with_times
        else
          self.message_type = :times
        end
        self.expected_times_invoked = times_invoked
        self
      end

      # keep (refactor me)
      def with(*arguments, &expectation_block)
        self.with_filter = WithFilter.new arguments, :args_must_match,  &expectation_block

        if message_type == :times
          self.message_type = :with_times
        else
          self.message_type = :with
        end
        arguments << expectation_block if expectation_block
        self.expected_arguments = arguments
        self
      end


      # === messages (can we get this out of here) ===

      # messages
      def message_for(message_category, message_type)
        message = MessagesFor::MESSAGES[:noun][message_category].fetch(message_type)
        ERB.new(message).result(binding)
      end

      # messages
      def inspect_arguments(arguments)
        inspected_arguments = arguments.map { |argument| inspect_argument argument }
        inspected_arguments << 'no args' if inspected_arguments.empty?
        "`" << inspected_arguments.join(", ") << "'"
      end

      # messages
      def inspect_argument(to_inspect)
        if RSpec.rspec_mocks_loaded? && to_inspect.respond_to?(:description)
          to_inspect.description
        else
          to_inspect.inspect
        end
      end

      # messages
      def times_invoked
        invocations.size
      end

      # messages
      def actual_invocation
        times_invoked = invocations.size
        times_invoked_with_expected_args = invocations.select { |invocation| args_match? invocation }.size
        if message_type == :with
          return message_for :other, :not_invoked if times_invoked.zero?
          inspected_invocations = invocations.map { |invocation| inspect_arguments invocation }
          "got #{inspected_invocations.join ', '}"
        else
          return message_for :other, :not_invoked if times_invoked.zero?
          "#{message_for :other, :invoked_description} #{times_msg times_invoked_with_expected_args}"
        end
      end

      # messages
      def times_msg(n)
        "#{n} time#{'s' unless n == 1}"
      end

      # messages (can we delete this?)
      def args_match?(actual_arguments)
        if RSpec.rspec_mocks_loaded?
          rspec_arg_expectation = ::RSpec::Mocks::ArgumentExpectation.new *expected_arguments
          rspec_arg_expectation.args_match? *actual_arguments
        else
          expected_arguments == actual_arguments
        end
      end
    end
  end
end
