class Surrogate
  module RSpec
    class WithFilter
      class BlockAsserter
        def initialize(block_to_test)
          self.block_to_test = block_to_test
        end

        def returns(value=nil, &block)
          @returns = block || lambda { value }
        end

        def before(&block)
          @before = block
        end

        def after(&block)
          @after = block
        end

        def arity(n)
          @arity = n
        end

        def match?
          @before && @before.call
          if @returns
            return_value = (@returns.call == block_to_test.call)
          else
            block_to_test.call
            return_value = true
          end
          return_value &&= (block_to_test.arity == @arity) if @arity
          @after && @after.call
          return_value
        end

        private

        attr_accessor :block_to_test
      end

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
          asserter = BlockAsserter.new(block_to_test)
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
  end
end
