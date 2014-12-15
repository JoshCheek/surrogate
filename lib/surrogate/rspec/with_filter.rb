require 'surrogate/rspec/block_asserter'

class Surrogate
  module RSpec
    class WithFilter

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
          ::RSpec::Mocks::ArgumentListMatcher
        end

        def approximate_2_11?
          Gem::Requirement.create('~> 2.11').satisfied_by? Gem::Version.new(::RSpec::Mocks::Version::STRING)
        end

        def approximate_3_0_0_rc?
          Gem::Requirement.create('~> 3.0.0.rc').satisfied_by? Gem::Version.new(::RSpec::Mocks::Version::STRING)
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
