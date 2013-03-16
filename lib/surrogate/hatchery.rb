class Surrogate

  # This manages the definitions that were given to the class
  # The hatchlings are added to the instances, and they look here
  # to find out about how their methods are implemented.
  class Hatchery

    # currently options don't do anything,
    # they're just there because the hatchery is the definition of the surrogate
    # so it makes sense for it to store values used by the endower when constructing clones
    attr_accessor :klass, :options

    def initialize(klass, options)
      self.klass      = klass
      self.options    = options
      @helper_methods = options.fetch :helper_methods, []
      klass_can_define_api_methods
    end

    def define(method_name, options={}, &block)
      add_api_method_for method_name
      add_verb_helpers_for method_name
      add_noun_helpers_for method_name
      api_methods[method_name] = MethodDefinition.new method_name, options, block
      klass
    end

    def api_methods
      @api_methods ||= {}
    end

    # We might not need this anymore, and I'm pretty sure the initialize thing is taken from
    # old implementation where we used to *always* hijack it, but now we don't.
    def api_method_names
      api_methods.keys - [:initialize]
    end

    def api_method_for(name)
      options = api_methods[name]
      options && options.default_proc
    end

    def helper_methods
      @helper_methods ||= []
    end

    private

    def klass_can_define_api_methods
      klass.singleton_class.__send__ :define_method, :define, &method(:define)
    end

    def add_api_method_for(method_name)
      klass.__send__ :define_method, method_name do |*args, &block|
        @hatchling.invoke_method method_name, args, &block
      end
    end

    def add_verb_helpers_for(method_name)
      add_helpers_for method_name, "will_#{method_name}"
    end

    def add_noun_helpers_for(method_name)
      add_helpers_for method_name, "will_have_#{method_name}"
    end

    def add_helpers_for(method_name, helper_name)
      helper_methods << helper_name.intern
      klass.__send__ :define_method, helper_name do |*args, &block|
        @hatchling.prepare_method method_name, args, &block
        self
      end
    end
  end
end

