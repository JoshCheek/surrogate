require 'set'
class Surrogate
  class ApiComparer

    # reflects on the surrogate to give info about methods that are useful for the comparer
    class SurrogateMethods < Struct.new(:surrogate)
      def methods
        { instance: {
            api:            instance_api_methods,
            inherited:      instance_inherited_methods,
            other:          instance_other_methods,
            without_bodies: instance_without_bodies,
          },
          class: {
            api:            class_api_methods,
            inherited:      class_inherited_methods,
            other:          class_other_methods,
            without_bodies: class_without_bodies,
          },
        }
      end

      def instance_api_methods
        Set.new class_hatchery.api_method_names
      end

      def instance_inherited_methods
        Set.new surrogate.instance_methods - surrogate.instance_methods(false)
      end

      def instance_other_methods
        Set.new(surrogate.instance_methods false) - instance_api_methods
      end

      def instance_without_bodies
        Set.new class_hatchery.api_method_names.reject { |name| class_hatchery.api_method_for name }
      end

      def class_api_methods
        Set.new singleton_class_hatchery.api_method_names
      end

      def class_inherited_methods
        Set.new surrogate.singleton_class.instance_methods - surrogate.singleton_class.instance_methods(false)
      end

      def class_other_methods
        Set.new(surrogate.singleton_class.instance_methods false) - class_api_methods - class_inherited_methods
      end

      def class_without_bodies
        Set.new singleton_class_hatchery.api_method_names.reject { |name| singleton_class_hatchery.api_method_for name }
      end

      def class_hatchery
        @class_hatchery ||= surrogate.instance_variable_get :@hatchery
      end

      def singleton_class_hatchery
        @singleton_class_hatchery ||= surrogate.singleton_class.instance_variable_get :@hatchery
      end
    end
  end
end
