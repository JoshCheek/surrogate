class Surrogate
  class NestBuilder
    def self.build(klass, &playlist)
      new(klass, &playlist).build
    end

    attr_accessor :klass, :playlist

    def initialize(klass, &playlist)
      self.klass, self.playlist = klass, playlist
    end

    def build
      build_for_klass
      build_for_singleton_class
    end

  private

    def build_for_klass
      an_egg_for                             klass
      teach_singing_to                       klass
      record_initialization_for_instances_of klass
      remember_invocations_for_instances_of  klass
      remember_invocations_for_instances_of  klass.singleton_class
      hijack_instantiation_of                klass
      can_get_a_new                          klass
    end

    def build_for_singleton_class
      egg = an_egg_for singleton
      teach_singing_to singleton
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
        song :initialize do |*args, &block|
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
        Surrogate.for new_klass do
          surrogate.songs.each do |songname, options|
            song songname, options.to_hash, &options.default_proc
          end
        end
        @egg.songs.each do |songname, options|
          new_klass.song songname, options.to_hash, &options.default_proc
        end
        new_klass
      end
    end

    def remember_invocations_for_instances_of(klass)
      klass.send :define_method, :invocations do |songname|
        @surrogate.invocations songname
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

    def teach_singing_to(klass)
      def klass.song(song, options={}, &block)
        @egg.song song, options, block
      end

      def klass.song_names
        @egg.song_names
      end
    end
  end
end
