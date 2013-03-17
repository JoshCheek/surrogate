require 'surrogate/method_signature'

class Surrogate
  # can we introduce one more object to hide from the Method the fact that it is dealing with a surrogate or an actual?
  # for example, it is shitty that this class can't just be used on two arbitrary objects,
  # and it is shitty that it has to have logic to look into the surrogate and get its actual method definition
  class MethodComparison
    attr_accessor :class_or_instance, :name, :surrogate, :actual
    def initialize(class_or_instance, name, surrogate, actual)
      raise ArgumentError, "Expected :class or :instance, got #{class_or_instance.inspect}" unless [:class, :instance].include? class_or_instance
      self.class_or_instance = class_or_instance
      self.name              = name
      self.surrogate         = surrogate
      self.actual            = actual
    end

    def inspect
      "#<S:AC:Method #{class_or_instance.inspect} #{name.inspect}>"
    end

    def on_surrogate?
      surrogate_method
    end

    def on_actual?
      actual_method
    end

    def api_method?
      hatchery.api_method_names.include? name
    end

    def inherited_on_surrogate?
      if class_method?
        surrogate_method && surrogate_method.owner != surrogate.singleton_class
      else
        surrogate_method && surrogate_method.owner != surrogate
      end
    end

    def inherited_on_actual?
      if class_method?
        actual_method && actual_method.owner != actual.singleton_class
      else
        actual_method && actual_method.owner != actual
      end
    end

    def class_method?
      class_or_instance == :class
    end

    def instance_method?
      class_or_instance == :instance
    end

    def reflectable?
      on_surrogate? && on_actual? && surrogate_parameters.reflectable? && actual_parameters.reflectable?
    end

    def types_match?
      reflectable? && surrogate_parameters.param_types == actual_parameters.param_types
    end

    def names_match?
      reflectable? && surrogate_parameters.param_names == actual_parameters.param_names
    end

    def surrogate_parameters
      raise NoMethodToCheckSignatureOf, name unless surrogate_method
      if api_method?
        block = hatchery.api_method_for name
        MethodSignature.new name, Helpers.block_to_lambda(block).parameters
      else
        MethodSignature.new name, surrogate_method.parameters
      end
    end

    def actual_parameters
      raise NoMethodToCheckSignatureOf, name unless actual_method
      MethodSignature.new name, actual_method.parameters
    end

    private

    def surrogate_method
      @surrogate_method ||= method_from surrogate
    end

    def actual_method
      @actual_method ||= method_from actual
    end

    def method_from(klass)
      if class_or_instance == :class
        klass.method name if klass.respond_to? name
      else
        klass.instance_method name if klass.allocate.respond_to? name
      end
    end

    def hatchery
      @hatchery ||= if class_method?
        surrogate.singleton_class.instance_variable_get :@hatchery
      else
        surrogate.instance_variable_get :@hatchery
      end
    end
  end
end
