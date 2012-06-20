class Surrogate
  module RSpec
    class WithFilter

      class BlockAsserter
        def initialize(definition_block)
          definition_block.call self
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

        def matches?(block_to_test)
          ensure_before_passes
          if @returns
            matches = (@returns.call == block_to_test.call)
          else
            block_to_test.call
            matches = true
          end
          matches &&= (block_to_test.arity == @arity) if @arity
          @after && @after.call
          matches
        end

        private

        # call before block once before any invocation
        def ensure_before_passes
          return if @before_has_been_invoked
          @before_has_been_invoked = true
          @before && @before.call
        end

        attr_accessor :block_to_test
      end




      # rename args to invocation
      attr_accessor :expected_invocation, :block, :pass, :filter_name

      def initialize(args=[], filter_name=:default_filter, &block)
        self.expected_invocation = Invocation.new args.dup, &block
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
        lambda { |invocation| args_match?(invocation) && blocks_match?(invocation) }
      end

      def blocks_match?(actual_invocation)
        # surely this is wrong
        return true unless expected_invocation.has_block?
        return unless actual_invocation.has_block?
        block_asserter.matches? actual_invocation.block
      end

      def block_asserter
        @block_asserter ||= BlockAsserter.new expected_invocation.block
      end

      def args_match?(actual_invocation)
        if RSpec.rspec_mocks_loaded?
          rspec_arg_expectation = ::RSpec::Mocks::ArgumentExpectation.new *expected_invocation.args
          rspec_arg_expectation.args_match? *actual_invocation.args
        else
          expected_arguments == actual_arguments
        end
      end
    end
  end
end
