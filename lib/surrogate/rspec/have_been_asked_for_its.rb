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
        attr_accessor :args, :block

        def initialize(args, &block)
          self.args = args
          self.block = block
        end

        def filter(invocations)

        end
      end

      attr_reader :handler, :times_predicate

      def initialize(expected)
        self.subject = expected
        self.message_type = :default
        @times_predicate = TimesPredicate.new(0, :<)
      end

      def matches?(mocked_instance)
        self.instance = mocked_instance

        # :)
        if message_type == :with_times
          times_predicate.matches?(invocations.select { |invocation| args_match? invocation })

        # :)
        elsif message_type == :default
          times_predicate.matches?(invocations)

        # :)
        elsif message_type == :times
          times_predicate.matches?(invocations)

        # :(
        elsif message_type == :with
          block_asserter = lambda { |invocation|
            return unless invocation.last.kind_of? Proc
            block_that_tests = expected_arguments.last
            block_to_test = invocation.last
            asserter = Handler::BlockAsserter.new(block_to_test)
            block_that_tests.call asserter
            asserter.match?
          }

          if expected_arguments.last.kind_of? Proc
            times_predicate.matches?(invocations.select { |invocation| block_asserter[invocation] })
          else
            times_predicate.matches?(invocations.select { |invocation| args_match? invocation })
          end
        end
      end

      attr_accessor :instance, :subject, :message_type
      attr_accessor :expected_times_invoked, :expected_arguments



      def message_for(message_category, message_type)
        message = MessagesFor::MESSAGES[:noun][message_category].fetch(message_type)
        ERB.new(message).result(binding)
      end

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

      def invocations
        instance.invocations(subject)
      end

      def times_invoked
        invocations.size
      end

      def times_invoked_with_expected_args
        invocations.select { |invocation| args_match? invocation }.size
      end

      def actual_invocation
        if message_type == :with
          return message_for :other, :not_invoked if times_invoked.zero?
          inspected_invocations = invocations.map { |invocation| inspect_arguments invocation }
          "got #{inspected_invocations.join ', '}"
        else
          return message_for :other, :not_invoked if times_invoked.zero?
          "#{message_for :other, :invoked_description} #{times_msg times_invoked_with_expected_args}"
        end
      end

      def times_msg(n)
        "#{n} time#{'s' unless n == 1}"
      end

      def failure_message_for_should
        message_for :should, message_type
      end

      def failure_message_for_should_not
        message_for :should_not, message_type
      end

      def times(times_invoked)
        if message_type == :with
          @times_predicate = TimesPredicate.new(times_invoked, :==)
          self.message_type = :with_times
        else
          @times_predicate = TimesPredicate.new(times_invoked, :==)
          self.message_type = :times
        end
        self.expected_times_invoked = times_invoked
        self
      end

      def with(*arguments, &expectation_block)
        if message_type == :times
          self.message_type = :with_times
        else
          self.message_type = :with
        end
        arguments << expectation_block if expectation_block
        self.expected_arguments = arguments
        self
      end

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
