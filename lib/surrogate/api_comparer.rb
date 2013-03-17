require 'surrogate/errors'
require 'surrogate/helpers'
require 'surrogate/method_comparison'

class Surrogate
  class ApiComparer
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
      all_methods.select(&:instance_method?).select(&:reflectable?).reject(&:types_match?)
    end

    def class_type_mismatches
      all_methods.select(&:class_method?).select(&:reflectable?).reject(&:types_match?)
    end

    def instance_name_mismatches
      all_methods.select(&:instance_method?).select(&:reflectable?).reject(&:names_match?)
    end

    def class_name_mismatches
      all_methods.select(&:class_method?).select(&:reflectable?).reject(&:names_match?)
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
      MethodComparison.new class_or_instance, name, surrogate, actual
    end
  end
end
