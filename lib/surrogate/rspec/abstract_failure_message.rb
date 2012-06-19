class Surrogate
  module RSpec
    class AbstractFailureMessage
      class ArgsInspector
        def self.inspect(arguments)
          inspected_arguments = arguments.map { |argument| inspect_argument argument }
          inspected_arguments << 'no args' if inspected_arguments.empty?
          "`" << inspected_arguments.join(", ") << "'"
        end

        def self.inspect_argument(to_inspect)
          if RSpec.rspec_mocks_loaded? && to_inspect.respond_to?(:description)
            to_inspect.description
          else
            to_inspect.inspect
          end
        end
      end

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
        ArgsInspector.inspect arguments
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
  end
end
