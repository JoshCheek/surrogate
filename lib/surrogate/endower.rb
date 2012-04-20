class Surrogate

  # adds surrogate behaviour to your class / singleton class / instances
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
      an_egg_for                             klass
      enable_defining_methods                klass
      record_initialization_for_instances_of klass
      remember_invocations_for_instances_of  klass
      remember_invocations_for_instances_of  klass.singleton_class
      hijack_instantiation_of                klass
      can_get_a_new                          klass
    end

    def endow_singleton_class
      egg = an_egg_for singleton
      enable_defining_methods singleton
      singleton.instance_eval &playlist if playlist
      klass.instance_variable_set :@surrogate, egg.hatch(klass)
      klass
    end

    # yeesh :( try to find a better way to do this
    def record_initialization_for_instances_of(klass)
      def klass.method_added(meth)
        return unless meth == :initialize && !@hijacking_initialize
        @hijacking_initialize = true
        current_initialize = instance_method :initialize
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

    def can_get_a_new(klass)
      klass.define_singleton_method :reprise do
        new_klass = Class.new self
        surrogate = @surrogate
        Surrogate.endow new_klass do
          surrogate.api_methods.each do |method_name, options|
            define method_name, options.to_hash, &options.default_proc
          end
        end
        @egg.api_methods.each do |method_name, options|
          new_klass.define method_name, options.to_hash, &options.default_proc
        end
        new_klass
      end
    end

    def remember_invocations_for_instances_of(klass)
      klass.send :define_method, :invocations do |method_name|
        @surrogate.invocations method_name
      end
    end

    def an_egg_for(klass)
      klass.instance_variable_set :@egg, Surrogate::Egg.new(klass)
    end

    def hijack_instantiation_of(klass)
      def klass.new(*args)
        instance = allocate
        egg = @egg
        instance.instance_eval { @surrogate = egg.hatch instance }
        instance.send :initialize, *args
        instance
      end
    end

    def enable_defining_methods(klass)
      def klass.define(method_name, options={}, &block)
        @egg.define method_name, options, block
      end

      def klass.api_method_names
        @egg.api_method_names
      end
    end
  end
end
