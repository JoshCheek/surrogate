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
          types:            instance_types,
        },
        class: {
          not_on_surrogate: class_not_on_surrogate,
          not_on_actual:    class_not_on_actual,
          types:            class_types,
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

    def class_types
      surrogate_class_methods         = surrogate_methods[:class][:api] + surrogate_methods[:class][:inherited]
      actual_class_methods            = actual_methods[:class][:inherited] + actual_methods[:class][:other]
      shared_class_methods            = surrogate_class_methods & actual_class_methods
      class_methods_that_should_match = shared_class_methods - surrogate_methods[:class][:without_bodies]
      class_methods_that_should_match.each_with_object Hash.new do |name, hash|
        surrogate_type, actual_type = class_types_for name
        next if surrogate_type == actual_type
        hash[name] = { surrogate: surrogate_type, actual: actual_type }
      end
    end

    def instance_types
      surrogate_instance_methods         = surrogate_methods[:instance][:api] + surrogate_methods[:instance][:inherited]
      actual_instance_methods            = actual_methods[:instance][:inherited] + actual_methods[:instance][:other]
      shared_instance_methods            = surrogate_instance_methods & actual_instance_methods
      instance_methods_that_should_match = shared_instance_methods - surrogate_methods[:instance][:without_bodies]
      instance_methods_that_should_match.each_with_object Hash.new do |name, hash|
        surrogate_type, actual_type = instance_types_for name
        next if surrogate_type == actual_type
        hash[name] = { surrogate: surrogate_type, actual: actual_type }
      end
    end

    private

    def class_types_for(name)
      surrogate_method = surrogate.api_method_for(:class, name)
      surrogate_method &&= to_lambda surrogate_method
      surrogate_method ||= surrogate.method name
      actual_method = actual.method name
      return type_for(surrogate_method), type_for(actual_method)
    end

    def instance_types_for(name)
      surrogate_method = surrogate.api_method_for(:instance, name)
      surrogate_method &&= to_lambda surrogate_method
      surrogate_method ||= surrogate.instance_method name
      actual_method = actual.instance_method name
      return type_for(surrogate_method), type_for(actual_method)
    end

    def type_for(method)
      method.parameters.map(&:first)
    end

    def to_lambda(proc)
      obj = Object.new
      obj.singleton_class.send :define_method, :abc123, &proc
      obj.method :abc123
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
        Set.new surrogate.api_method_names
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
        Set.new surrogate.singleton_class.api_method_names
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
