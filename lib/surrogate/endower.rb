class Surrogate

  # Adds surrogate behaviour to your class / singleton class / instances
  #
  # please refactor me! ...may not be possible :(
  class Endower
    def self.endow(klass, &playlist)
      new(klass, &playlist).endow
    end

    attr_accessor :klass, :playlist

    def initialize(klass, &playlist)
      self.klass, self.playlist = klass, playlist
    end

    def endow
      endow_klass
      endow_singleton_class
    end

  private

    def endow_klass
      add_hatchery_to                        klass
      klass.extend ClassMethods
      enable_defining_methods                klass
      record_initialization_for_instances_of klass
      remember_invocations_for_instances_of  klass
      remember_invocations_for_instances_of  klass.singleton_class
    end

    def endow_singleton_class
      hatchery = add_hatchery_to singleton
      enable_defining_methods singleton
      singleton.module_eval &playlist if playlist
      klass.instance_variable_set :@hatchling, Hatchling.new(klass, hatchery)
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
      klass.send :define_method, :initialize do |*args, &block|
        initialize.bind(self).call(*args, &block)
      end
    end

    def singleton
      klass.singleton_class
    end

    def remember_invocations_for_instances_of(klass)
      klass.send :define_method, :invocations do |method_name|
        @hatchling.invocations method_name
      end
    end

    def add_hatchery_to(klass)
      klass.instance_variable_set :@hatchery, Surrogate::Hatchery.new(klass)
    end

    def enable_defining_methods(klass)
      def klass.define(method_name, options={}, &block)
        @hatchery.define method_name, options, block
      end

      def klass.api_method_names
        @hatchery.api_method_names
      end
    end
  end


  # use a module so that the method is inherited (important for substitutability)
  module ClassMethods
    def clone
      hatchling, hatchery = @hatchling, @hatchery
      Class.new self do
        Surrogate.endow self do
          hatchling.api_methods.each { |name, options| define name, options.to_hash, &options.default_proc }
        end
        hatchery.api_methods.each { |name, options| define name, options.to_hash, &options.default_proc }
      end
    end

    # Custom new, because user can define initialize, and ivars should be set before it
    def new(*args)
      instance = allocate
      instance.instance_variable_set :@hatchling, Hatchling.new(instance, @hatchery)
      instance.send :initialize, *args
      instance
    end
  end
end
