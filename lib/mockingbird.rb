require 'mockingbird/version'
require 'Mockingbird/bird'
require 'Mockingbird/egg'
require 'Mockingbird/options'
require 'Mockingbird/song_queue'

class Mockingbird
  UnpreparedMethodError = Class.new StandardError

  def self.song_for(klass, &playlist)
    song_for_klass klass
    song_for_singleton_class klass, klass.singleton_class, playlist if playlist
    klass
  end

private
  def self.song_for_klass(klass)
    an_egg_for              klass
    teach_singing_to        klass
    hijack_instantiation_of klass
  end

  def self.song_for_singleton_class(klass, singleton, playlist)
    egg = an_egg_for singleton
    teach_singing_to singleton
    singleton.instance_eval &playlist
    klass.instance_variable_set :@mockingbird, egg.hatch(klass)
    klass
  end

  def self.an_egg_for(klass)
    klass.instance_variable_set :@egg, Mockingbird::Egg.new(klass)
  end

  def self.hijack_instantiation_of(klass)
    def klass.new(*args)
      instance = nil
      Mockingbird.without_initialize self do
        instance = super()
        egg = @egg
        instance.instance_eval { @mockingbird = egg.hatch instance }
      end
      instance.send :initialize, *args
      instance
    end
  end

  def self.teach_singing_to(klass)
    def klass.sing(song, options={}, &block)
      @egg.sing song, options, block
    end
  end

  # man, it took me forever to figure this out -.^
  def self.without_initialize(klass, &block)
    init = klass.instance_method :initialize
    return block.call if not_overridden? init
    owner = init.owner
    init  = owner.instance_method :initialize
    warnings_please_stfu do
      owner.send :remove_method, :initialize
      without_initialize klass, &block
      owner.send :define_method, :initialize, init
    end
  end

  def self.warnings_please_stfu
    saved_verbosity = $-v
    $-v = nil
    yield
  ensure
    $-v = saved_verbosity
  end

  def self.not_overridden?(init)
    init.owner == BasicObject
  end
end

# need to be able to define custom initialize methods

# need to marshall the default value?
