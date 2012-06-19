require 'surrogate/rspec/invocation_matcher'

class Surrogate
  module RSpec
    class HaveBeenToldTo < InvocationMatcher

      class FailureMessageInternal
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
      end


      class FailureMessageShouldDefault < FailureMessageInternal
        def get_message
          "was never told to #{ method_name }"
        end
      end

      class FailureMessageShouldWith < FailureMessageInternal
        def get_message
          "should have been told to #{ method_name } with #{ inspect_arguments expected_arguments }, but #{ actual_invocation }"
        end

        def actual_invocation
          times_invoked_with_expected_args = invocations.select { |actual_arguments|
            if RSpec.rspec_mocks_loaded?
              rspec_arg_expectation = ::RSpec::Mocks::ArgumentExpectation.new *expected_arguments
              rspec_arg_expectation.args_match? *actual_arguments
            else
              expected_arguments == actual_arguments
            end
          }.size

          return "was never told to" if times_invoked.zero?
          inspected_invocations = invocations.map { |invocation| inspect_arguments invocation }
          "got #{inspected_invocations.join ', '}"
        end
      end

      class FailureMessageShouldTimes < FailureMessageInternal
        def get_message
          "should have been told to #{ method_name } #{ times_msg expected_times_invoked } but was told to #{ method_name } #{ times_msg times_invoked }"
        end
      end

      class FailureMessageWithTimes < FailureMessageInternal
        def get_message
          "should have been told to #{ method_name } #{ times_msg expected_times_invoked } with #{ inspect_arguments expected_arguments }, but #{ actual_invocation }"
        end

        def actual_invocation
          times_invoked_with_expected_args = invocations.select { |actual_arguments|
            if RSpec.rspec_mocks_loaded?
              rspec_arg_expectation = ::RSpec::Mocks::ArgumentExpectation.new *expected_arguments
              rspec_arg_expectation.args_match? *actual_arguments
            else
              expected_arguments == actual_arguments
            end
          }.size

          return "was never told to" if times_invoked.zero?
          "got it #{times_msg times_invoked_with_expected_args}"
        end
      end

      class FailureMessageShouldNotDefault < FailureMessageInternal
        def get_message
          "shouldn't have been told to #{ method_name }, but was told to #{ method_name } #{ times_msg times_invoked }"
        end
      end

      class FailureMessageShouldNotWith < FailureMessageInternal
        def get_message
          "should not have been told to #{ method_name } with #{ inspect_arguments expected_arguments }, but #{ actual_invocation }"
        end

        def actual_invocation
          times_invoked_with_expected_args = invocations.select { |actual_arguments|
            if RSpec.rspec_mocks_loaded?
              rspec_arg_expectation = ::RSpec::Mocks::ArgumentExpectation.new *expected_arguments
              rspec_arg_expectation.args_match? *actual_arguments
            else
              expected_arguments == actual_arguments
            end
          }.size

          return "was never told to" if times_invoked.zero?
          inspected_invocations = invocations.map { |invocation| inspect_arguments invocation }
          "got #{inspected_invocations.join ', '}"
        end
      end

      class FailureMessageShouldNotTimes < FailureMessageInternal
        def get_message
          "shouldn't have been told to #{ method_name } #{ times_msg expected_times_invoked }, but was"
        end
      end

      class FailureMessageShouldNotWithTimes < FailureMessageInternal
        def get_message
          "should not have been told to #{ method_name } #{ times_msg expected_times_invoked } with #{ inspect_arguments expected_arguments }, but #{ actual_invocation }"
        end

        def actual_invocation
          times_invoked_with_expected_args = invocations.select { |actual_arguments|
            if RSpec.rspec_mocks_loaded?
              rspec_arg_expectation = ::RSpec::Mocks::ArgumentExpectation.new *expected_arguments
              rspec_arg_expectation.args_match? *actual_arguments
            else
              expected_arguments == actual_arguments
            end
          }.size

          return "was never told to" if times_invoked.zero?
          "got it #{times_msg times_invoked_with_expected_args}"
        end
      end


      def failure_message_for_should
        message_class =
            if times_predicate.default? && with_filter.default?
              FailureMessageShouldDefault
            elsif times_predicate.default?
              FailureMessageShouldWith
            elsif with_filter.default?
              FailureMessageShouldTimes
            else
              FailureMessageWithTimes
            end
        message_class.new(method_name, invocations, with_filter, times_predicate).get_message
      end

      def failure_message_for_should_not
        message_class =
            if times_predicate.default? && with_filter.default?
              FailureMessageShouldNotDefault
            elsif times_predicate.default?
              FailureMessageShouldNotWith
            elsif with_filter.default?
              FailureMessageShouldNotTimes
            else
              FailureMessageShouldNotWithTimes
            end
        message_class.new(method_name, invocations, with_filter, times_predicate).get_message
      end
    end
  end
end
