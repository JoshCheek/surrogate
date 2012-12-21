require 'set'
require 'surrogate/surrogate_class_reflector'
require 'surrogate/porc_reflector'

class Surrogate

  # compares a surrogate to an object
  class ApiComparer
    attr_accessor :surrogate, :actual

    def initialize(actual, surrogate)
      unless surrogate.instance_variable_get(:@hatchery).kind_of?(Hatchery) && surrogate.instance_variable_get(:@hatchling).kind_of?(Hatchling)
        surrogate, actual = actual, surrogate
      end
      self.surrogate, self.actual = surrogate, actual
    end

    def surrogate_methods
      @surrogate_methods ||= SurrogateClassReflector.new(surrogate).methods
    end

    def actual_methods
      @actual_methods ||= PorcReflector.new(actual).methods
    end

    def compare
      @compare ||= {
        instance: {
          not_on_surrogate: instance_not_on_surrogate,
          not_on_actual:    instance_not_on_actual,
          types:            instance_types,
          names:            instance_names,
        },
        class: {
          not_on_surrogate: class_not_on_surrogate,
          not_on_actual:    class_not_on_actual,
          types:            class_types,
          names:            class_names,
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


    # there is a lot of duplication in these next four methods -.-
    # idk if there is something we can do about it.
    #
    # The class methods below ignore the .clone method, b/c it's interface is intentionally different.
    # This is so stupid, it needs to get smarter, it needs a way for the Surrogate or the user to tell it
    # what to care about, it shouldn't have to know about what the endower is doing.
    #
    # In general, this code is just really fucking bad. I'd like to create some sort of method object
    # that can encapsulate all of this information (mthod name, param names, types, existence)
    # but I can't quite see it yet, and I'm scared to refactor to it since this code is tested primarily
    # through unit tests (this is one of the few places I resorted to unit tests, and I'm so unhappy that
    # I did).

    # types are only shown for methods on both objects
    def class_types
      class_methods_that_should_match.each_with_object Hash.new do |name, hash|
        surrogate_type, actual_type = class_types_for name
        next if surrogate_type == actual_type || name == :clone # ugh :(
        hash[name] = { surrogate: surrogate_type, actual: actual_type }
      end
    end

    # types are only shown for methods on both objects
    def instance_types
      instance_methods_that_should_match.each_with_object Hash.new do |name, hash|
        surrogate_type, actual_type = instance_types_for name
        next if surrogate_type == actual_type
        hash[name] = { surrogate: surrogate_type, actual: actual_type }
      end
    end

    # names are only shown for methods on both objects
    def class_names
      class_methods_that_should_match.each_with_object Hash.new do |method_name, hash|
        surrogate_name, actual_name = class_parameter_names_for method_name
        next if surrogate_name == actual_name || method_name == :clone # ugh :(
        hash[method_name] = { surrogate: surrogate_name, actual: actual_name }
      end
    end

    # names are only shown for methods on both objects
    def instance_names
      instance_methods_that_should_match.each_with_object Hash.new do |method_name, hash|
        surrogate_name, actual_name = instance_parameter_names_for method_name
        next if surrogate_name == actual_name
        hash[method_name] = { surrogate: surrogate_name, actual: actual_name }
      end
    end

    private

    def instance_methods_that_should_match
      surrogate_instance_methods         = surrogate_methods[:instance][:api] + surrogate_methods[:instance][:inherited]
      actual_instance_methods            = actual_methods[:instance][:inherited] + actual_methods[:instance][:other]
      instance_methods_that_should_match = (surrogate_instance_methods & actual_instance_methods) - surrogate_methods[:instance][:without_bodies] - actual_methods[:instance][:without_bodies]
    end

    def class_methods_that_should_match
      surrogate_class_methods         = surrogate_methods[:class][:api] + surrogate_methods[:class][:inherited]
      actual_class_methods            = actual_methods[:class][:inherited] + actual_methods[:class][:other]
      (surrogate_class_methods & actual_class_methods) - surrogate_methods[:class][:without_bodies] - actual_methods[:class][:without_bodies]
    end

    # there is a lot of duplication in these next four methods -.-
    # also, it seems like a lot of this shit could move into the reflectors

    def class_types_for(name)
      surrogate_method = class_api_method_for name
      surrogate_method &&= to_lambda surrogate_method
      surrogate_method ||= surrogate.method name
      actual_method = actual.method name
      return type_for(surrogate_method), type_for(actual_method)
    end

    def instance_types_for(name)
      surrogate_method = instance_api_method_for name
      surrogate_method &&= to_lambda surrogate_method
      surrogate_method ||= surrogate.instance_method name
      actual_method = actual.instance_method name
      return type_for(surrogate_method), type_for(actual_method)
    end

    def class_parameter_names_for(name)
      surrogate_method = class_api_method_for name
      surrogate_method &&= to_lambda surrogate_method
      surrogate_method ||= surrogate.method name
      actual_method = actual.method name
      return parameter_names_for(surrogate_method), parameter_names_for(actual_method)
    end

    def instance_parameter_names_for(name)
      surrogate_method = instance_api_method_for name
      surrogate_method &&= to_lambda surrogate_method
      surrogate_method ||= surrogate.instance_method name
      actual_method = actual.instance_method name
      return parameter_names_for(surrogate_method), parameter_names_for(actual_method)
    end

    def type_for(method)
      method.parameters.map(&:first)
    end

    def parameter_names_for(method)
      method.parameters.map(&:last)
    end

    def to_lambda(proc)
      obj = Object.new
      obj.singleton_class.send :define_method, :abc123, &proc
      obj.method :abc123
    end

    def instance_api_method_for(name)
      class_hatchery.api_method_for name
    end

    def class_api_method_for(name)
      singleton_class_hatchery.api_method_for name
    end

    def class_hatchery
      @class_hatchery ||= surrogate.instance_variable_get :@hatchery
    end

    def singleton_class_hatchery
      @singleton_class_hatchery ||= surrogate.singleton_class.instance_variable_get :@hatchery
    end
  end
end
