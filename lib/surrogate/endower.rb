class Surrogate

  # Adds surrogate behaviour to your class / singleton class / instances
  #
  # please refactor me! ...may not be possible :(
  # Can we move all method definitions into this class?
  class Endower
    def self.add_hook(&block)
      hooks << block
    end

    def self.hooks
      @hooks ||= []
    end

    def self.endow(klass, &block)
      new(klass, &block).endow
    end

    attr_accessor :klass, :block

    def initialize(klass, &block)
      self.klass, self.block = klass, block
    end

    def endow
      endow_klass
      endow_singleton_class
    end

  private

    def endow_klass
      klass.extend ClassMethods
      add_hatchery_to                        klass
      enable_defining_methods                klass
      remember_invocations_for_instances_of  klass
      klass.send :include, InstanceMethods
      invoke_hooks                           klass
    end

    def endow_singleton_class
      hatchery = add_hatchery_to singleton
      enable_defining_methods singleton
      singleton.module_eval &block if block
      klass.instance_variable_set :@hatchling, Hatchling.new(klass, hatchery)
      remember_invocations_for_instances_of  singleton
      invoke_hooks                           singleton
      klass
    end

    def invoke_hooks(klass)
      self.class.hooks.each { |hook| hook.call klass }
    end

    def singleton
      klass.singleton_class
    end

    # Can we expose this in another object?
    def remember_invocations_for_instances_of(klass)
      klass.__send__ :define_method, :invocations do |method_name|
        @hatchling.invocations method_name
      end
    end

    def add_hatchery_to(klass)
      klass.instance_variable_set :@hatchery, Surrogate::Hatchery.new(klass)
    end

    def enable_defining_methods(klass)
      def klass.define(method_name, options={}, &block)
        @hatchery.define method_name, options, &block
      end
    end
  end


  # use a module so that the method is inherited (important for substitutability)
  module ClassMethods

    # Should this be dup? (dup seems to copy singleton methods) and may be able to use #initialize_copy to reset ivars
    # Can we just remove this feature an instead provide a reset feature which could be hooked into in before/after blocks (e.g. https://github.com/rspec/rspec-core/blob/622505d616d950ed53d12c6e82dbb953ba6241b4/lib/rspec/core/mocking/with_rspec.rb)
    def clone
      hatchling, hatchery, parent_name = @hatchling, @hatchery, name
      Class.new self do
        extend Module.new { define_method(:name) { parent_name && parent_name + '.clone' } } # inherit the name -- use module so that ApiComparison comes out correct (real classes inherit their name method)
        Surrogate.endow self do
          hatchling.api_methods.each { |name, options| define name, options.to_hash, &options.default_proc }
        end
        hatchery.api_methods.each { |name, options| define name, options.to_hash, &options.default_proc }
      end
    end

    # Custom new, because user can define initialize, and we need to record it
    def new(*args)
      instance = allocate
      self.last_instance = instance
      instance.instance_variable_set :@hatchling, Hatchling.new(instance, @hatchery)
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
      methods = SurrogateReflector.new(self).methods
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
      methods = SurrogateReflector.new(self.class).methods[:instance][:api].sort.take(4)
      methods[-1] = '...' if methods.size == 4
      methods << 'no api' if methods.empty?
      class_name = self.class.name || 'AnonymousSurrogate'
      "#<#{class_name}: #{methods.join ' '}>"
    end
  end
end
