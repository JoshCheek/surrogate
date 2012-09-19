require 'set'
class Surrogate
  # reflects on the Plain Old Ruby Class to give info about methods that are useful for the comparer
  class PorcReflector < Struct.new(:actual)
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
end
