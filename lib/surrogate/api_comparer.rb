require 'set'

class Surrogate

  # compares a surrogate to an object
  class ApiComparer
    attr_accessor :surrogate, :actual

    def initialize(surrogate, actual)
      self.surrogate, self.actual = surrogate, actual
    end

    def surrogate_methods
      @surrogate_methods ||= SurrogateMethods.new(surrogate).methods
    end

    def actual_methods
      @actual_methods ||= ActualMethods.new(actual).methods
    end

    def compare
      @compare ||= {
        instance: {
          not_on_surrogate: instance_not_on_surrogate,
          not_on_actual:    instance_not_on_actual,
        },
        class: {
          not_on_surrogate: class_not_on_surrogate,
          not_on_actual:    class_not_on_actual,
        },
      }
    end

    def instance_not_on_surrogate
      (actual_methods[:instance][:inherited] + actual_methods[:instance][:other]) -
        (surrogate_methods[:instance][:inherited] + surrogate_methods[:instance][:api])
    end

    def instance_not_on_actual
      surrogate_methods[:instance][:api] - actual_methods[:instance][:inherited] - actual_methods[:instance][:other]
    end

    def class_not_on_surrogate
      (actual_methods[:class][:inherited] + actual_methods[:class][:other]) -
        (surrogate_methods[:class][:inherited] + surrogate_methods[:class][:api])
    end

    def class_not_on_actual
      surrogate_methods[:class][:api] - actual_methods[:class][:inherited] - actual_methods[:class][:other]
    end

    # methods from the actual class (as opposed to "these are actually methods"
    class ActualMethods < Struct.new(:actual)
      def methods
        { instance: {
            inherited: instance_inherited_methods,
            other:     instance_other_methods,
          },
          class: {
            inherited: class_inherited_methods,
            other:     class_other_methods,
          },
        }
      end

      def instance_inherited_methods
        Set.new actual.instance_methods - actual.instance_methods(false)
      end

      def instance_other_methods
        Set.new(actual.instance_methods) - instance_inherited_methods
      end

      def class_inherited_methods
        Set.new actual.singleton_class.instance_methods - actual.singleton_class.instance_methods(false)
      end

      def class_other_methods
        Set.new(actual.singleton_class.instance_methods) - class_inherited_methods
      end
    end


    class SurrogateMethods < Struct.new(:surrogate)
      def methods
        { instance: {
            api:       instance_api_methods,
            inherited: instance_inherited_methods,
            other:     instance_other_methods,
          },
          class: {
            api:       class_api_methods,
            inherited: class_inherited_methods,
            other:     class_other_methods,
          },
        }
      end

      def instance_api_methods
        Set.new surrogate.api_method_names
      end

      def instance_inherited_methods
        Set.new surrogate.instance_methods - surrogate.instance_methods(false)
      end

      def instance_other_methods
        Set.new(surrogate.instance_methods false) - instance_api_methods
      end

      def class_api_methods
        Set.new surrogate.singleton_class.api_method_names
      end

      def class_inherited_methods
        Set.new surrogate.singleton_class.instance_methods - surrogate.singleton_class.instance_methods(false)
      end

      def class_other_methods
        Set.new(surrogate.singleton_class.instance_methods false) - class_api_methods - class_inherited_methods
      end
    end
  end
end
