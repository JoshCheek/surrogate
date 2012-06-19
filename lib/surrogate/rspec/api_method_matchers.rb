require 'erb'
require 'surrogate/rspec/gtfo_my_face'


class Surrogate
  module RSpec
    class Handler
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






      attr_accessor :instance, :subject, :language_type, :message_type
      attr_accessor :expected_times_invoked, :expected_arguments


      def initialize(subject, language_type)
        self.subject, self.language_type = subject, language_type
        self.message_type = :default
      end

      def message_for(message_category, message_type)
        message = MessagesFor::MESSAGES[language_type][message_category].fetch(message_type)
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

      def match?
        if message_type == :default
          times_invoked > 0
        elsif message_type == :times
          expected_times_invoked == times_invoked
        elsif message_type == :with_times
          times_invoked_with_expected_args == expected_times_invoked
        end
      end

      def times_invoked_with_expected_args
        invocations.select { |invocation| args_match? invocation }.size
      end

      def actual_invocation
        return message_for :other, :not_invoked if times_invoked.zero?
        "#{message_for :other, :invoked_description} #{times_msg times_invoked_with_expected_args}"
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
          self.message_type = :with_times
        else
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
          extend MatchWithArguments
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



    module MatchWithArguments

      def match?
        block_asserter = lambda { |invocation|
          return unless invocation.last.kind_of? Proc
          block_that_tests = expected_arguments.last
          block_to_test = invocation.last
          asserter = Handler::BlockAsserter.new(block_to_test)
          block_that_tests.call asserter
          asserter.match?
        }

        if expected_arguments.last.kind_of? Proc
          invocations.select { |invocation| block_asserter[invocation] }.any?
        else
          invocations.any? { |invocation| args_match? invocation }
        end
      end

      def actual_invocation
        return message_for :other, :not_invoked if times_invoked.zero?
        inspected_invocations = invocations.map { |invocation| inspect_arguments invocation }
        "got #{inspected_invocations.join ', '}"
      end
    end

    module CommonMatcher
      attr_reader :handler

      def initialize(expected)
        @handler = Handler.new expected, self.class::LANGUAGE_TYPE
      end

      def matches?(mocked_instance)
        handler.instance = mocked_instance
        handler.match?
      end

      def failure_message_for_should_not
        handler.failure_message_for_should_not
      end

      def failure_message_for_should
        handler.failure_message_for_should
      end
    end


    module Matchers
      def have_been_told_to(expected)
        HaveBeenToldTo.new expected
      end

      def have_been_asked_for_its(expected)
        HaveBeenAskedForIts.new expected
      end

      def have_been_initialized_with(*initialization_args, &block)
        HaveBeenInitializedWith.new *initialization_args, &block
      end
    end
  end
end

require 'surrogate/rspec/have_been_asked_for_its'
require 'surrogate/rspec/have_been_initialized_with'
require 'surrogate/rspec/have_been_told_to'
