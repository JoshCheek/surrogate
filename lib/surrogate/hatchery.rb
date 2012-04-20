class Surrogate
  class Hatchery
    attr_accessor :klass

    def initialize(klass)
      self.klass = klass
      defines_methods
    end

    def defines_methods
      klass.singleton_class.send :define_method, :define, &method(:define)
    end

    def define(method_name, options={}, block)
      add_api_methods_for method_name
      api_methods[method_name] = Options.new options, block
    end

    def api_methods
      @api_methods ||= {}
    end

    def api_method_names
      api_methods.keys - [:initialize]
    end

    # here we need to find better domain terminology
    def add_api_methods_for(method_name)
      klass.send :define_method, method_name do |*args, &block|
        @surrogate.invoke_method method_name, args, &block
      end

      # verbs
      klass.send :define_method, "will_#{method_name}" do |*args, &block|
        @surrogate.prepare_method method_name, args, &block
        self
      end

      klass.send :define_method, "will_#{method_name}_queue" do |*args, &block|
        @surrogate.prepare_method_queue method_name, args, &block
        self
      end

      # nouns
      klass.send :alias_method, "will_have_#{method_name}", "will_#{method_name}"
      klass.send :alias_method, "will_have_#{method_name}_queue", "will_#{method_name}_queue"
    end
  end
end

