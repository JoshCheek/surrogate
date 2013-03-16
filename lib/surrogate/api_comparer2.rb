require 'surrogate/errors'

class Surrogate
  class ApiComparer2
    class Method
      class Signature
        attr_accessor :name, :params
        def initialize(name, params)
          self.name, self.params = name, params
        end

        def param_names
          params.map(&:last)
        end

        def param_types
          params.map(&:first)
        end
      end

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
        if class_method?
          singleton_class_hatchery.api_method_names.include? name
        else
          class_hatchery.api_method_names.include? name
        end
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

      def types_match?
        on_surrogate? && on_actual? && surrogate_parameters.param_types == actual_parameters.param_types
      end

      def names_match?
        on_surrogate? && on_actual? && surrogate_parameters.param_names == actual_parameters.param_names
      end

      def surrogate_parameters
        raise NoMethodToCheckSignatureOf, name unless surrogate_method
        Signature.new name, surrogate_method.parameters
      end

      def actual_parameters
        raise NoMethodToCheckSignatureOf, name unless actual_method
        Signature.new name, actual_method.parameters
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

      def class_hatchery
        @class_hatchery ||= surrogate.instance_variable_get :@hatchery
      end

      def singleton_class_hatchery
        @singleton_class_hatchery ||= surrogate.singleton_class.instance_variable_get :@hatchery
      end
    end
  end

  class ApiComparer2
    attr_accessor :surrogate, :actual

    def initialize(options)
      self.surrogate = options.fetch :surrogate
      self.actual    = options.fetch :actual
    end

    def all_methods
      @all_methods ||= generate_class_methods + generate_instance_methods
    end

    def extra_instance_methods
      all_methods.select(&:instance_method?).select(&:on_surrogate?).reject(&:on_actual?)
    end

    def extra_class_methods
      all_methods.select(&:class_method?).select(&:on_surrogate?).reject(&:on_actual?)
    end

    def missing_instance_methods
      all_methods.select(&:instance_method?).reject(&:on_surrogate?).select(&:on_actual?)
    end

    def missing_class_methods
      all_methods.select(&:class_method?).reject(&:on_surrogate?).select(&:on_actual?)
    end

    def instance_type_mismatches
      all_methods.select(&:instance_method?).select(&:on_surrogate?).select(&:on_actual?).reject(&:types_match?)
    end

    def class_type_mismatches
      all_methods.select(&:class_method?).select(&:on_surrogate?).select(&:on_actual?).reject(&:types_match?)
    end

    private

    def generate_class_methods
      # can we get some helper obj to encapsulate this kind of prying into the object?
      helper_methods = surrogate.singleton_class.instance_variable_get(:@hatchery).helper_methods
      methods = (surrogate.public_methods | actual.public_methods) - helper_methods
      methods.map { |name| to_method :class, name }
    end

    def generate_instance_methods
      helper_methods = surrogate.instance_variable_get(:@hatchery).helper_methods
      methods = (surrogate.public_instance_methods | actual.public_instance_methods) - helper_methods
      methods.map { |name| to_method :instance, name }
    end

    def to_method(class_or_instance, name)
      Method.new class_or_instance, name, surrogate, actual
    end
  end
end
