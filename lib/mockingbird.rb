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
    remember_invocations_on klass
    hijack_instantiation_of klass
  end

  def self.remember_invocations_on(klass)
    invoker = lambda { |songname| @mockingbird.invocations songname }
    klass.send :define_method, :invocations, &invoker
    klass.define_singleton_method :invocations, &invoker
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
      instance = allocate
      egg = @egg
      instance.instance_eval { @mockingbird = egg.hatch instance }
      instance.send :initialize, *args
      instance
    end
  end

  def self.teach_singing_to(klass)
    def klass.sing(song, options={}, &block)
      @egg.sing song, options, block
    end
  end
end

# need to be able to define custom initialize methods

# need to marshall the default value?
