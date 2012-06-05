class Surrogate

  # Adds surrogate behaviour to your class / singleton class / instances
  #
  # please refactor me! ...may not be possible :(
  # Can we move all method definitions into this class?
  class Endower
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
      record_initialization_for_instances_of klass
      remember_invocations_for_instances_of  klass
    end

    def endow_singleton_class
      hatchery = add_hatchery_to singleton
      enable_defining_methods singleton
      singleton.module_eval &block if block
      klass.instance_variable_set :@hatchling, Hatchling.new(klass, hatchery)
      remember_invocations_for_instances_of  singleton
      klass
    end

    # yeesh :( pretty sure there isn't a better way to do this
    def record_initialization_for_instances_of(klass)
      def klass.method_added(meth)
        return if meth != :initialize || @hijacking_initialize
        @hijacking_initialize = true
        current_initialize = instance_method :initialize

        # `define' records the args while maintaining the old behaviour
        # we have to do it stupidly like this because there is no to_proc on an unbound method
        define :initialize do |*args, &block|
          current_initialize.bind(self).call(*args, &block)
        end
      ensure
        @hijacking_initialize = false
      end
      initialize = klass.instance_method :initialize
      klass.__send__ :define_method, :initialize do |*args, &block|
        initialize.bind(self).call(*args, &block)
      end
    end

    def singleton
      klass.singleton_class
    end

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

      def klass.api_method_names
        @hatchery.api_method_names
      end
    end
  end


  # use a module so that the method is inherited (important for substitutability)
  module ClassMethods

    # Should this be dup? (dup seems to copy singleton methods) and may be able to use #initialize_copy to reset ivars
    # Can we just remove this feature an instead provide a reset feature which could be hooked into in before/after blocks (e.g. https://github.com/rspec/rspec-core/blob/622505d616d950ed53d12c6e82dbb953ba6241b4/lib/rspec/core/mocking/with_rspec.rb)
    def clone
      hatchling, hatchery = @hatchling, @hatchery
      Class.new self do
        Surrogate.endow self do
          hatchling.api_methods.each { |name, options| define name, options.to_hash, &options.default_proc }
        end
        hatchery.api_methods.each { |name, options| define name, options.to_hash, &options.default_proc }
      end
    end

    # Custom new, because user can define initialize, and we need to record it
    # Can we move this into the redefinition of initialize and have it explicitly record itself?
    def new(*args)
      instance = allocate
      instance.instance_variable_set :@hatchling, Hatchling.new(instance, @hatchery)
      instance.send :initialize, *args
      instance
    end
  end
end
