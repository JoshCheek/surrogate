require 'mockingbird/version'
require 'Mockingbird/bird'
require 'Mockingbird/egg'
require 'Mockingbird/options'
require 'Mockingbird/song_queue'

class Mockingbird
  UnpreparedMethodError = Class.new StandardError

  def self.for(klass, &playlist)
    for_klass klass
    for_singleton_class klass, klass.singleton_class, playlist
    klass
  end

private
  def self.for_klass(klass)
    an_egg_for                             klass
    teach_singing_to                       klass
    record_initialization_for_instances_of klass
    remember_invocations_for_instances_of  klass
    remember_invocations_for_instances_of  klass.singleton_class
    hijack_instantiation_of                klass
    can_get_a_new                          klass
  end

  # yeesh :( try to find a better way to do this
  def self.record_initialization_for_instances_of(klass)
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

  def self.for_singleton_class(klass, singleton, playlist)
    egg = an_egg_for singleton
    teach_singing_to singleton
    singleton.instance_eval &playlist if playlist
    klass.instance_variable_set :@mockingbird, egg.hatch(klass)
    klass
  end

  def self.can_get_a_new(klass)
    klass.define_singleton_method :reprise do
      new_klass = Class.new self
      mockingbird = @mockingbird
      Mockingbird.for new_klass do
        mockingbird.songs.each do |songname, options|
          song songname, options.to_hash, &options.default_proc
        end
      end
      @egg.songs.each do |songname, options|
        new_klass.song songname, options.to_hash, &options.default_proc
      end
      new_klass
    end
  end

  def self.remember_invocations_for_instances_of(klass)
    klass.send :define_method, :invocations do |songname|
      @mockingbird.invocations songname
    end
  end

  def self.an_egg_for(klass)
    klass.instance_variable_set :@egg, Mockingbird::Egg.new(klass)
  end

  def self.hijack_instantiation_of(klass)
    def klass.new(*args)
      instance = allocate
      egg = @egg
      instance.instance_eval { @mockingbird = egg.hatch instance }
      instance.send :initialize, *args
      instance
    end
  end

  def self.teach_singing_to(klass)
    def klass.song(song, options={}, &block)
      @egg.song song, options, block
    end
  end
end

# need to marshall the default value?
