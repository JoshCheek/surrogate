class Surrogate

  # Adds surrogate behaviour to your class / singleton class / instances
  #
  # please refactor me! ...may not be possible :(
  # Can we move all method definitions into this class?
  class Endower
    def self.uninitialized_instance_for(surrogate_class)
      instance = surrogate_class.allocate
      hatchery = surrogate_class.instance_variable_get :@hatchery
      surrogate_class.last_instance = instance
      instance.instance_variable_set :@hatchling, Hatchling.new(instance, hatchery)
      instance
    end

    def self.add_hook(&block)
      hooks << block
    end

    def self.hooks
      @hooks ||= []
    end

    def self.endow(klass, options, &block)
      new(klass, options, &block).endow
    end

    attr_accessor :klass, :block, :options

    def initialize(klass, options, &block)
      self.klass, self.options, self.block = klass, options, block
    end

    def endow
      endow_klass
      endow_singleton_class
    end

  private

    def endow_klass
      klass.extend ClassMethods
      add_hatchery_to klass, options # do we want to pick out which options to pass?
      enable_defining_methods klass
      enable_factory          klass, options.fetch(:factory, :factory)
      klass.send :include, InstanceMethods
      enable_generic_override klass
      invoke_hooks klass
    end

    def endow_singleton_class
      hatchery = add_hatchery_to singleton
      enable_defining_methods singleton
      singleton.module_eval &block if block
      klass.instance_variable_set :@hatchling, Hatchling.new(klass, hatchery)
      invoke_hooks singleton
      klass
    end

    def enable_generic_override(klass)
      klass.__send__ :define_method, :will_override do |method_name, *args, &block|
        @hatchling.prepare_method method_name, args, &block
        self
      end
    end

    def invoke_hooks(klass)
      self.class.hooks.each { |hook| hook.call klass }
    end

    def singleton
      klass.singleton_class
    end

    def add_hatchery_to(klass, options={})
      klass.instance_variable_set :@hatchery, Surrogate::Hatchery.new(klass, options)
    end

    def enable_defining_methods(klass)
      def klass.define(method_name, options={}, &block)
        block ||= lambda {}
        @hatchery.define method_name.to_sym, options, &block
      end

      def klass.define_reader(*method_names, &block)
        method_names.each { |method_name| define method_name, &block }
        self
      end

      def klass.define_writer(*method_names)
        method_names.each do |method_name|
          define "#{method_name}=" do |value|
            instance_variable_set("@#{method_name}", value)
          end
        end
        self
      end

      def klass.define_accessor(*method_names, &block)
        define_reader(*method_names, &block)
        define_writer(*method_names)
        self
      end
    end

    def enable_factory(klass, factory_name)
      return unless factory_name
      klass.define_singleton_method factory_name do |overrides={}|
        instance = begin
                     new
                   rescue ArgumentError
                     Endower.uninitialized_instance_for self
                   end
        overrides.each { |attribute, value| instance.will_override attribute, value }
        instance
      end
    end
  end


  # use a module so that the method is inherited (important for substitutability)
  module ClassMethods

    # Should this be dup? (dup seems to copy singleton methods) and may be able to use #initialize_copy to reset ivars
    # Can we just remove this feature an instead provide a reset feature which could be hooked into in before/after blocks (e.g. https://github.com/rspec/rspec-core/blob/622505d616d950ed53d12c6e82dbb953ba6241b4/lib/rspec/core/mocking/with_rspec.rb)
    def clone(overrides={})
      hatchling, hatchery, parent_name = @hatchling, @hatchery, name
      Class.new self do
        extend Module.new { define_method(:name) { parent_name && parent_name + '.clone' } } # inherit the name -- use module so that ApiComparison comes out correct (real classes inherit their name method)
        Surrogate.endow self, hatchery.options do
          hatchling.api_methods.each { |name, options| define name, options.to_hash, &options.default_proc }
        end
        hatchery.api_methods.each { |name, options| define name, options.to_hash, &options.default_proc }
        overrides.each { |attribute, value| @hatchling.prepare_method attribute, [value] }
      end
    end

    # Custom new, because user can define initialize, and we need to record it
    def new(*args)
      instance = Endower.uninitialized_instance_for self
      instance.__send__ :initialize, *args
      instance
    end

    def last_instance
      Thread.current["surrogate_last_instance_#{self.object_id}"]
    end

    def last_instance=(instance)
      Thread.current["surrogate_last_instance_#{self.object_id}"] = instance
    end


    def inspect
      return name if name
      methods = SurrogateClassReflector.new(self).methods
      method_inspections = []

      # add class methods
      if methods[:class][:api].any?
        meth_names = methods[:class][:api].to_a.sort.take(4)
        meth_names[-1] = '...' if meth_names.size == 4
        method_inspections << "Class: #{meth_names.join ' '}"
      end

      # add instance methods
      if methods[:instance][:api].any?
        meth_names = methods[:instance][:api].to_a.sort.take(4)
        meth_names[-1] = '...' if meth_names.size == 4
        method_inspections << "Instance: #{meth_names.join ' '}"
      end

      # when no class or instance methods
      method_inspections << "no api" if method_inspections.empty?

      "AnonymousSurrogate(#{method_inspections.join ', '})"
    end
  end

  # Use module so the method is inherited. This allows proper matching (e.g. other object will inherit inspect from Object)
  module InstanceMethods
    def inspect
      methods = SurrogateClassReflector.new(self.class).methods[:instance][:api].sort.take(4)
      methods[-1] = '...' if methods.size == 4
      methods << 'no api' if methods.empty?
      class_name = self.class.name || 'AnonymousSurrogate'
      "#<#{class_name}: #{methods.join ' '}>"
    end
  end
end
