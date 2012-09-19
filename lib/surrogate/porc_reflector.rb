require 'set'
class Surrogate
  # reflects on the Plain Old Ruby Class to give info about methods that are useful for the comparer
  class PorcReflector < Struct.new(:actual)
    def methods
      { instance: {
          inherited:      instance_inherited_methods,
          other:          instance_other_methods,
          without_bodies: instance_without_bodies,
        },
        class: {
          inherited:      class_inherited_methods,
          other:          class_other_methods,
          without_bodies: class_without_bodies,
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

    def class_without_bodies
      Set.new actual.methods.select { |name| actual.method(name).parameters.any? { |param| param.size == 1 } }
    end

    def instance_without_bodies
      Set.new actual.instance_methods.select { |name| actual.instance_method(name).parameters.any? { |param| param.size == 1 } }
    end
  end
end
