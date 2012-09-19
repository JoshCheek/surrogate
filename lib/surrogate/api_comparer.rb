require 'set'
require 'surrogate/api_comparer/surrogate_methods'
require 'surrogate/api_comparer/actual_methods'

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
      class_methods_that_should_match = (surrogate_class_methods & actual_class_methods) - surrogate_methods[:class][:without_bodies]
      class_methods_that_should_match.each_with_object Hash.new do |name, hash|
        surrogate_type, actual_type = class_types_for name
        next if surrogate_type == actual_type
        hash[name] = { surrogate: surrogate_type, actual: actual_type }
      end
    end

    def instance_types
      surrogate_instance_methods         = surrogate_methods[:instance][:api] + surrogate_methods[:instance][:inherited]
      actual_instance_methods            = actual_methods[:instance][:inherited] + actual_methods[:instance][:other]
      instance_methods_that_should_match = (surrogate_instance_methods & actual_instance_methods) - surrogate_methods[:instance][:without_bodies]
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
  end
end
