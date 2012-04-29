class Surrogate

  # This manages the definitions that were given to the class
  # The hatchlings are added to the instances, and they look here
  # to find out about how their methods are implemented.
  class Hatchery
    attr_accessor :klass

    def initialize(klass)
      self.klass = klass
      klass_can_define_api_methods
    end

    def define(method_name, options={}, block)
      add_api_method_for method_name
      add_verb_helpers_for method_name
      add_noun_helpers_for method_name
      api_methods[method_name] = Options.new options, block
      klass
    end

    def api_methods
      @api_methods ||= {}
    end

    def api_method_names
      api_methods.keys - [:initialize]
    end

    private

    def klass_can_define_api_methods
      klass.singleton_class.send :define_method, :define, &method(:define)
    end

    def add_api_method_for(method_name)
      klass.send :define_method, method_name do |*args, &block|
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
      klass.send :define_method, helper_name do |*args, &block|
        if args.size == 1
          @hatchling.prepare_method method_name, args, &block
        else
          @hatchling.prepare_method_queue method_name, args, &block
        end
        self
      end
    end
  end
end

