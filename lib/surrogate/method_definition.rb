require 'surrogate/argument_errorizer'

class Surrogate

  # A surrogate's `define` keyword results in one of these
  class MethodDefinition
    attr_accessor :name, :options, :default_proc

    def initialize(name, options, default_proc)
      self.name, self.options, self.default_proc = name, options, default_proc
    end

    def has?(name)
      options.has_key? name
    end

    def [](key)
      options[key]
    end

    def to_hash
      options
    end

    def must_match!(args)
      default_proc && errorizer.match!(*args)
    end

    def default(instance, invocation, &no_default)
      if options.has_key? :default
        options[:default]
      elsif default_proc
        default_proc_as_method_on(instance).call(*invocation.args, &invocation.block)
      else
        no_default.call
      end
    end

    private

    def errorizer
      @errorizer ||= ArgumentErrorizer.new name, to_method_definition(default_proc)
    end

    def default_proc_as_method_on(instance)
      unique_name = "surrogate_temp_method_#{Time.now.to_i}_#{rand 10000000}"
      klass = instance.singleton_class
      klass.__send__ :define_method, unique_name, &default_proc
      as_method = klass.instance_method unique_name
      klass.__send__ :remove_method, unique_name
      as_method.bind instance
    end

    def to_method_definition(default_proc)
      object = Object.new
      object.define_singleton_method(:temp_method, &default_proc)
      object.method(:temp_method)
    end
  end
end

