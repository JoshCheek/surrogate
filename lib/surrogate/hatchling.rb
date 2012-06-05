class Surrogate
  UnknownMethod = Class.new StandardError


  # This contains the unique behaviour for each instance
  # It handles method invocation and records the appropriate information
  class Hatchling
    attr_accessor :instance, :hatchery

    def initialize(instance, hatchery)
      self.instance, self.hatchery = instance, hatchery
    end

    def api_methods
      hatchery.api_methods
    end

    def invoke_method(method_name, args, &block)
      invoked_methods[method_name] << args
      return get_default method_name, args, &block unless has_ivar? method_name
      Value.factory(get_ivar method_name).value(self, method_name)
    end

    def prepare_method(method_name, args, &block)
      set_ivar method_name, Value.factory(*args, &block)
    end

    def invocations(method_name)
      invoked_methods[method_name]
    end

    # maybe these four should be extracted into their own class
    def has_ivar?(method_name)
      instance.instance_variable_defined? ivar_for method_name
    end

    def set_ivar(method_name, value)
      instance.instance_variable_set ivar_for(method_name), value
    end

    def get_ivar(method_name)
      instance.instance_variable_get ivar_for method_name
    end

    def unset_ivar(method_name)
      instance.__send__ :remove_instance_variable, ivar_for(method_name)
    end

    def ivar_for(method_name)
      case method_name
      when /\?$/
        "@#{method_name.to_s.chop}_p"
      else
        "@#{method_name}"
      end
    end

  private

    def invoked_methods
      @invoked_methods ||= Hash.new do |hash, method_name|
        must_know method_name
        hash[method_name] = []
      end
    end

    def get_default(method_name, args, &block)
      api_methods[method_name].default instance, args, block do
        raise UnpreparedMethodError, "#{method_name} has been invoked without being told how to behave"
      end
    end

    def must_know(method_name)
      return if api_methods.has_key? method_name
      known_methods = api_methods.keys.map(&:to_s).map(&:inspect).join ', '
      raise UnknownMethod, "doesn't know \"#{method_name}\", only knows #{known_methods}"
    end
  end
end

