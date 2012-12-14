require 'surrogate/rspec/abstract_failure_message'
require 'surrogate/rspec/times_predicate'
require 'surrogate/rspec/with_filter'
require 'surrogate/surrogate_instance_reflector'

class Surrogate
  module RSpec
    class InvocationMatcher
      attr_accessor :times_predicate, :with_filter, :surrogate, :method_name

      def initialize(method_name)
        self.method_name     = method_name.to_sym
        self.times_predicate = TimesPredicate.new
        self.with_filter     = WithFilter.new
      end

      def matches?(surrogate)
        self.surrogate = surrogate
        times_predicate.matches? filtered_args
      end

      def filtered_args
        @filtered_args ||= with_filter.filter invocations
      end

      def invocations
        SurrogateInstanceReflector.new(surrogate).invocations(method_name)
      end

      def failure_message_for_should
        raise "THIS METHOD SHOULD HAVE BEEN OVERRIDDEN"
      end

      def failure_message_for_should_not
        raise "THIS METHOD SHOULD HAVE BEEN OVERRIDDEN"
      end

      def times(times_invoked)
        @times_predicate = TimesPredicate.new(times_invoked, :==)
        self
      end

      def with(*arguments, &expectation_block)
        self.with_filter = WithFilter.new arguments, :args_must_match,  &expectation_block
        arguments << expectation_block if expectation_block
        self
      end

      def failure_message_for_should
        message_for(
          if times_predicate.default? && with_filter.default?
            :FailureMessageShouldDefault
          elsif times_predicate.default?
            :FailureMessageShouldWith
          elsif with_filter.default?
            :FailureMessageShouldTimes
          else
            :FailureMessageWithTimes
          end
        )
      end

      def failure_message_for_should_not
        message_for(
          if times_predicate.default? && with_filter.default?
            :FailureMessageShouldNotDefault
          elsif times_predicate.default?
            :FailureMessageShouldNotWith
          elsif with_filter.default?
            :FailureMessageShouldNotTimes
          else
            :FailureMessageShouldNotWithTimes
          end
        )
      end

      def message_for(failure_class_name)
        self.class.const_get(failure_class_name).new(method_name, invocations, with_filter, times_predicate).get_message
      end
    end
  end
end
