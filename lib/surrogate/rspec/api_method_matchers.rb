require 'erb'


class Surrogate
  module RSpec
    module MessagesFor

      MESSAGES = {
        verb: {
          should: {
            default:    "was never told to <%= subject %>",
            with:       "should have been told to <%= subject %> with <%= inspect_arguments expected_arguments %>, but <%= actual_invocation %>",
            times:      "should have been told to <%= subject %> <%= times_msg expected_times_invoked %> but was told to <%= subject %> <%= times_msg times_invoked %>",
            with_times: "should have been told to <%= subject %> <%= times_msg expected_times_invoked %> with <%= inspect_arguments expected_arguments %>, but <%= actual_invocation %>",
          },
          should_not: {
            default:    "shouldn't have been told to <%= subject %>, but was told to <%= subject %> <%= times_msg times_invoked %>",
            with:       "should not have been told to <%= subject %> with <%= inspect_arguments expected_arguments %>, but <%= actual_invocation %>",
            times:      "shouldn't have been told to <%= subject %> <%= times_msg expected_times_invoked %>, but was",
            with_times: "should not have been told to <%= subject %> <%= times_msg expected_times_invoked %> with <%= inspect_arguments expected_arguments %>, but <%= actual_invocation %>",
          },
          other: {
            not_invoked: "was never told to",
            invoked_description: "got it",
          },
        },
        noun: {
          should: {
            default:    "was never asked for its <%= subject %>",
            with:       "should have been asked for its <%= subject %> with <%= inspect_arguments expected_arguments %>, but <%= actual_invocation %>",
            times:      "should have been asked for its <%= subject %> <%= times_msg expected_times_invoked %>, but was asked <%= times_msg times_invoked %>",
            with_times: "should have been asked for its <%= subject %> <%= times_msg expected_times_invoked %> with <%= inspect_arguments expected_arguments %>, but <%= actual_invocation %>",
          },
          should_not: {
            default:    "shouldn't have been asked for its <%= subject %>, but was asked <%= times_msg times_invoked %>",
            with:       "should not have been asked for its <%= subject %> with <%= inspect_arguments expected_arguments %>, but <%= actual_invocation %>",
            times:      "shouldn't have been asked for its <%= subject %> <%= times_msg expected_times_invoked %>, but was",
            with_times: "should not have been asked for its <%= subject %> <%= times_msg expected_times_invoked %> with <%= inspect_arguments expected_arguments %>, but <%= actual_invocation %>",
          },
          other: {
            not_invoked: "was never asked",
            invoked_description: "was asked",
          },
        },
      }

      def message_for(language_type, message_category, message_type, binding)
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

      extend self
    end


    # IGNORE EVERYTHING ABOVE THIS LINE ##################################################


    class Handler < Struct.new(:subject, :language_type)
      attr_accessor :instance

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

      def message_type
        :default
      end

      def invocations
        instance.invocations(subject)
      end

      def times_invoked
        invocations.size
      end

      def match?
        times_invoked > 0
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
        extend (kind_of?(MatchWithArguments) ? MatchNumTimesWith : MatchNumTimes)
        self.expected_times_invoked = times_invoked
        self
      end

      def with(*arguments, &expectation_block)
        extend (kind_of?(MatchNumTimes) ? MatchNumTimesWith : MatchWithArguments)
        arguments << expectation_block if expectation_block
        self.expected_arguments = arguments
        self
      end
    end


    module ArgumentComparer
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
      include ArgumentComparer

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

      attr_accessor :expected_arguments

      def message_type
        :with
      end

      def match?
        if expected_arguments.last.kind_of? Proc
          begin
            invocations.select { |invocation| block_matches? invocation }
                       .any?
                       # .any?   { |invocation| args_match?    invocation }
          ensure
          end
        else
          invocations.any? { |invocation| args_match? invocation }
        end
      end

      def block_matches?(invocation)
        return unless invocation.last.kind_of? Proc
        block_that_tests = expected_arguments.last
        block_to_test = invocation.last
        asserter = BlockAsserter.new(block_to_test)
        block_that_tests.call asserter
        asserter.match?
      end

      def actual_invocation
        return message_for :other, :not_invoked if times_invoked.zero?
        inspected_invocations = invocations.map { |invocation| inspect_arguments invocation }
        "got #{inspected_invocations.join ', '}"
      end
    end


    module MatchNumTimes
      def message_type
        :times
      end

      attr_accessor :expected_times_invoked

      def match?
        expected_times_invoked == times_invoked
      end
    end


    module MatchNumTimesWith
      include ArgumentComparer

      def message_type
        :with_times
      end

      attr_accessor :expected_times_invoked, :expected_arguments

      def times_invoked_with_expected_args
        invocations.select { |invocation| args_match? invocation }.size
      end

      def match?
        times_invoked_with_expected_args == expected_times_invoked
      end

      def actual_invocation
        return message_for :other, :not_invoked if times_invoked.zero?
        "#{message_for :other, :invoked_description} #{times_msg times_invoked_with_expected_args}"
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


    class HaveBeenInitializedWith
      LANGUAGE_TYPE = :verb

      include CommonMatcher

      def initialize(*initialization_args, &block)
        super :initialize
        handler.with *initialization_args, &block
      end
    end


    class HaveBeenAskedForIts
      LANGUAGE_TYPE = :noun

      include CommonMatcher

      def times(number)
        handler.times number
        self
      end

      def with(*arguments, &block)
        handler.with *arguments, &block
        self
      end
    end


    class HaveBeenToldTo
      LANGUAGE_TYPE = :verb

      include CommonMatcher

      def times(number)
        handler.times number
        self
      end

      def with(*arguments, &block)
        handler.with *arguments, &block
        self
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
