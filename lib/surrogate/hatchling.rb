class Surrogate
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
      invocation = Invocation.new(args, &block)
      invoked_methods[method_name] << invocation
      if setter?(method_name) || !has_ivar?(method_name)
        return get_default method_name, invocation, &block
      end
      interfaces_must_match! method_name, args
      Value.factory(get_ivar method_name).value(method_name)
    end

    def prepare_method(method_name, args, &block)
      must_know method_name
      set_ivar method_name, Value.factory(*args, &block)
    end

    def invocations(method_name)
      invoked_methods[method_name]
    end

  private

    def setter?(method_name)
      method_name.match(/\w=$/)
    end

    def invoked_methods
      @invoked_methods ||= Hash.new do |hash, method_name|
        must_know method_name
        hash[method_name] = []
      end
    end

    def interfaces_must_match!(method_name, args)
      api_methods[method_name].must_match! args
    end

    def get_default(method_name, invocation)
      api_methods[method_name].default instance, invocation
    end

    def must_know(method_name)
      return if api_methods.has_key? method_name
      if api_methods.empty?
        message = "doesn't know \"#{method_name}\", doesn't know anything! It's an epistemological conundrum, go define #{method_name}."
      else
        known_methods = api_methods.keys.map(&:to_s).map(&:inspect).join ', '
        message = "doesn't know \"#{method_name}\", only knows #{known_methods}"
      end
      raise UnknownMethod, message
    end

    # maybe these ivar methods should be extracted into their own class
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
      method_name = method_name.to_s
      if    method_name.end_with? ?? then "@#{method_name.to_s.chop}_p"
      elsif method_name.end_with? ?! then "@#{method_name.to_s.chop}_b"
      elsif method_name == '[]'      then '@_brackets'
      elsif method_name == '**'      then '@_splat_splat'
      elsif method_name == '!@'      then '@_ubang'
      elsif method_name == '+@'      then '@_uplus'
      elsif method_name == '-@'      then '@_uminus'
      elsif method_name == ?*        then '@_splat'
      elsif method_name == ?/        then '@_divide'
      elsif method_name == ?%        then '@_percent'
      elsif method_name == ?+        then '@_plus'
      elsif method_name == ?-        then '@_minus'
      elsif method_name == '>>'      then '@_shift_right'
      elsif method_name == '<<'      then '@_shift_left'
      elsif method_name == ?&        then '@_ampersand'
      elsif method_name == ?^        then '@_caret'
      elsif method_name == ?|        then '@_bang'
      elsif method_name == '<='      then '@_less_eq'
      elsif method_name == ?<        then '@_less'
      elsif method_name == ?>        then '@_greater'
      elsif method_name == '>='      then '@_greater_eq'
      elsif method_name == '<=>'     then '@_spaceship'
      elsif method_name == '=='      then '@_2eq'
      elsif method_name == '==='     then '@_3eq'
      elsif method_name == '!='      then '@_not_eq'
      elsif method_name == '=~'      then '@_eq_tilde'
      elsif method_name == '!~'      then '@_bang_tilde'
      else                                "@#{method_name}"
      end
    end

  end
end

