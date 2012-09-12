class Surrogate
  module RSpec
    class WithFilter

      class BlockAsserter
        def initialize(definition_block)
          @call_with = Invocation.new []
          definition_block.call self
        end

        def call_with(*args, &block)
          @call_with = Invocation.new args, &block
        end

        def returns(value=nil, &block)
          @returns = block || lambda { |returned| returned.should == value }
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
          matches   = before_matches? block_to_test
          matches &&= return_value_matches? block_to_test
          matches &&= arity_matches? block_to_test
          matches &&= after_matches? block_to_test
          matches
        end

        private

        # matches if no return specified, or returned value == specified value
        def return_value_matches?(block_to_test)
          returned_value = block_to_test.call(*@call_with.args, &@call_with.block)
          @returns.call returned_value if @returns
          true
        rescue ::RSpec::Expectations::ExpectationNotMetError
          false
        end

        # matches if the first time it is called, it raises nothing
        def before_matches?(*)
          @before_has_been_invoked || (@before && @before.call)
        ensure
          return @before_has_been_invoked = true unless $!
        end

        # matches if nothing is raised
        def after_matches?(block_to_test)
          @after && @after.call
          true
        end

        def arity_matches?(block_to_test)
          return true unless @arity
          block_to_test.arity == @arity
        end

        attr_accessor :block_to_test
      end



      class RSpecMatchAsserter
        attr_accessor :actual_invocation, :expected_invocation

        def initialize(actual_invocation, expected_invocation)
          self.actual_invocation, self.expected_invocation = actual_invocation, expected_invocation
        end

        def match?
          rspec_arg_expectation = matcher_class.new *expected_invocation.args
          rspec_arg_expectation.args_match? *actual_invocation.args
        end

        def matcher_class
          return ::RSpec::Mocks::ArgumentListMatcher if approximate_2_11?
          ::RSpec::Mocks::ArgumentExpectation
        end

        def approximate_2_11?
          Gem::Requirement.create('~> 2.11').satisfied_by? Gem::Version.new(::RSpec::Mocks::Version::STRING)
        end
      end



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
          RSpecMatchAsserter.new(actual_invocation, expected_invocation).match?
        else
          expected_arguments == actual_arguments
        end
      end
    end
  end
end
