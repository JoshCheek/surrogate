require "mockingbird/version"

class Mockingbird
  class Options
    attr_accessor :options, :default_proc

    def initialize(options, default_proc)
      self.options, self.default_proc = options, default_proc
    end

    def has?(name)
      options.has_key? name
    end

    def [](key)
      options[key]
    end

    def default(instance, args, &no_default)
      return options[:default] if options.has_key? :default
      return instance.instance_exec(*args, &default_proc) if default_proc
      no_default.call
    end
  end
end


class Mockingbird
  class Egg
    attr_accessor :klass

    def initialize(klass)
      self.klass = klass
      learn_to_sing
    end

    def hatch(instance)
      Bird.new instance, self
    end

    def learn_to_sing
      klass.singleton_class.send :define_method, :sing, &method(:sing)
    end

    def sing(songname, options={}, block)
      add_song_methods_for songname
      songs[songname] = Options.new options, block
    end

    def songs
      @songs ||= {}
    end

    # here we need to find better domain terminology
    def add_song_methods_for(songname)
      klass.send :define_method, songname do |*args, &block|
        @mockingbird.play_song songname, args, &block
      end

      klass.send :define_method, "will_#{songname}" do |*args, &block|
        @mockingbird.prepare_song songname, args, &block
      end

      klass.send :define_method, "will_#{songname}_queue" do |*args, &block|
        @mockingbird.prepare_song_queue songname, args, &block
      end
    end
  end
end

class Mockingbird
  class SongQueue < Struct.new(:queue)
    QueueEmpty = Class.new StandardError

    def dequeue
      raise QueueEmpty if empty?
      queue.shift
    end

    def empty?
      queue.empty?
    end
  end
end

class Mockingbird
  class Bird
    attr_accessor :instance, :egg

    def initialize(instance, egg)
      self.instance, self.egg = instance, egg
      set_hard_defaults
    end

    def songs
      egg.songs
    end

    def play_song(songname, args, &block)
      return get_default songname, args unless has_ivar? songname
      ivar = get_ivar songname
      return var_from_queue ivar, songname if ivar.kind_of? SongQueue
      ivar
    end

    def var_from_queue(queue, songname)
      result = queue.dequeue
      reset_var songname if queue.empty?
      result
    end

    def prepare_song(songname, args, &block)
      set_ivar songname, *args
    end

    def prepare_song_queue(songname, args, &block)
      set_ivar songname, SongQueue.new(args)
    end

    def get_default(songname, args)
      songs[songname].default instance, args do
        raise UnpreparedMethodError, "#{songname} hasn't been invoked without being told how to behave"
      end
    end

  private

    def set_hard_defaults
      songs.each do |songname, options|
        next unless options.has? :default!
        set_ivar songname, options[:default!]
      end
    end

    def has_ivar?(songname)
      instance.instance_variable_defined? "@#{songname}"
    end

    def reset_var(songname)
      unset_ivar songname
      set_ivar songname, songs[songname][:default!] if songs[songname].has? :default!
    end

    def set_ivar(songname, value)
      instance.instance_variable_set "@#{songname}", value
    end

    def get_ivar(songname)
      instance.instance_variable_get "@#{songname}"
    end

    def unset_ivar(songname)
      instance.send :remove_instance_variable, "@#{songname}"
    end
  end
end



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
      instance = super
      egg = @egg
      instance.instance_eval { @mockingbird = egg.hatch instance }
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
