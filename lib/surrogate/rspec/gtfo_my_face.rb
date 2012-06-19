class Surrogate
  module RSpec

    # This entire class needs to go away (be replaced by FailureMessages)
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




    # lets try to move everything from here into FailureMessage
    class FailureMessages
      attr_accessor :times_predicate, :invocations, :with_filter, :message

      def initialize(invocations, with_filter, times_predicate, message)
        self.invocations = invocations
        self.with_filter = with_filter
        self.times_predicate = times_predicate
        self.message = message
      end

      def render
        message.result(self)
      end

      def message_type
        if times_predicate.default? && with_filter.default?
          :default
        elsif times_predicate.default?
          :with
        elsif with_filter.default?
          :times
        else
          :with_times
        end
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

      def expected_arguments
        with_filter.args
      end

      def expected_times_invoked
        times_predicate.expected_times_invoked
      end

      def actual_invocation
        times_invoked = invocations.size
        times_invoked_with_expected_args = invocations.select { |actual_arguments|
          if RSpec.rspec_mocks_loaded?
            rspec_arg_expectation = ::RSpec::Mocks::ArgumentExpectation.new *expected_arguments
            rspec_arg_expectation.args_match? *actual_arguments
          else
            expected_arguments == actual_arguments
          end
        }.size

        times_msg = lambda { |n| "#{n} time#{'s' unless n == 1}" }

        # this is unfortunately only useful for HaveBeenToldTo, need to abstract them out
        if message_type == :with
          return "was never told to" if times_invoked.zero?
          inspected_invocations = invocations.map { |invocation| inspect_arguments invocation }
          "got #{inspected_invocations.join ', '}"
        else
          return "was never told to" if times_invoked.zero?
          "got it #{times_msg.call times_invoked_with_expected_args}"
        end
      end

      def times_msg(n)
        "#{n} time#{'s' unless n == 1}"
      end
    end
  end
end
