class Surrogate

  # adds surrogate behaviour to your class / singleton class / instances
  #
  # please refactor me!
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
      a_hatchery_for                         klass
      enable_defining_methods                klass
      record_initialization_for_instances_of klass
      remember_invocations_for_instances_of  klass
      remember_invocations_for_instances_of  klass.singleton_class
      hijack_instantiation_of                klass
      can_get_a_new                          klass
    end

    def endow_singleton_class
      hatchery = a_hatchery_for singleton
      enable_defining_methods singleton
      singleton.module_eval &playlist if playlist
      klass.instance_variable_set :@surrogate, Hatchling.new(klass, hatchery)
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
      klass.extend Module.new {
        # use a module so that the method is inherited (important for substitutability)
        def clone
          new_klass = Class.new self
          surrogate = @surrogate
          Surrogate.endow new_klass do
            surrogate.api_methods.each do |method_name, options|
              define method_name, options.to_hash, &options.default_proc
            end
          end
          @hatchery.api_methods.each do |method_name, options|
            new_klass.define method_name, options.to_hash, &options.default_proc
          end
          new_klass
        end
      }
    end

    def remember_invocations_for_instances_of(klass)
      klass.send :define_method, :invocations do |method_name|
        @surrogate.invocations method_name
      end
    end

    def a_hatchery_for(klass)
      klass.instance_variable_set :@hatchery, Surrogate::Hatchery.new(klass)
    end

    def hijack_instantiation_of(klass)
      # use a module so that the method is inherited (important for substitutability)
      klass.extend Module.new {
        def new(*args)
          instance = allocate
          hatchery = @hatchery
          instance.instance_eval { @surrogate = Hatchling.new instance, hatchery }
          instance.send :initialize, *args
          instance
        end
      }
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
end
