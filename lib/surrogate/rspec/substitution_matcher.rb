class Surrogate
  module RSpec
    class SubstitutionMatcher
      def initialize(original_class, options={})
        @original_class = original_class
        @comparison     = nil
        @subset_only    = options.fetch :subset, false
        @types          = options.fetch :types,  true
        @names          = options.fetch :names,  false
      end

      def matches?(surrogate)
        # uhm, this sucks, figure out what we actually want to do
        unless surrogate.instance_variable_get(:@hatchery).kind_of?(Hatchery) && surrogate.instance_variable_get(:@hatchling).kind_of?(Hatchling)
          @original_class, surrogate = surrogate, @original_class
        end
        @surrogate = surrogate
        comparison = ApiComparer.new(surrogate: surrogate, actual: @original_class)
        @failure_message = failure_messages_for comparison
        !@failure_message
      end

      def failure_message_for_should
        @failure_message
      end

      def failure_messages_for(comparison)
        differences = []

        if comparison.extra_instance_methods.any?
          names = comparison.extra_instance_methods.map(&:name)
          differences << "has extra instance methods: #{names.inspect}"
        end

        if comparison.extra_class_methods.any?
          names = comparison.extra_class_methods.map(&:name)
          differences << "has extra class methods: #{names.inspect}"
        end

        if !@subset_only && comparison.missing_instance_methods.any?
          names = comparison.missing_instance_methods.map(&:name)
          differences << "is missing instance methods: #{names.inspect}"
        end

        if !@subset_only && comparison.missing_class_methods.any?
          names = comparison.missing_class_methods.map(&:name)
          differences << "is missing class methods: #{names.inspect}"
        end

        # if both types and names differ, we should just print one error message

        if @types # these error messages are not tested
          comparison.instance_type_mismatches.each { |method|
            differences << "#{@surrogate.inspect}##{method.surrogate_parameters.inspect} has different types than #{@original_class.inspect}##{method.actual_parameters.inspect}"
          }
          # this case is not tested at all
          comparison.class_type_mismatches.each { |method|
            differences << "#{@surrogate.inspect}.#{method.surrogate_parameters.inspect} has different types than #{@original_class.inspect}##{method.actual_parameters.inspect}"
          }
        end

        if @names # these error messages are not tested
          comparison.instance_name_mismatches.each { |method|
            differences << "#{@surrogate.inspect}##{method.surrogate_parameters.inspect} has different names than #{@original_class.inspect}##{method.actual_parameters.inspect}"
          }
          comparison.class_name_mismatches.each { |method|
            differences << "#{@surrogate.inspect}##{method.surrogate_parameters.inspect} has different names than #{@original_class.inspect}##{method.actual_parameters.inspect}"
          }
        end

        return if differences.empty?
        "Was not substitutable because surrogate " << differences.join("\n")
      end

      def failure_message_for_should_not
        "Should not have been substitutable, but was"
      end
    end
  end
end
