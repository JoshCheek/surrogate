class Surrogate
  UnknownSong = Class.new StandardError
  class Bird
    attr_accessor :instance, :egg

    def initialize(instance, egg)
      self.instance, self.egg = instance, egg
    end

    def songs
      egg.songs
    end

    def play_song(songname, args, &block)
      played_songs[songname] << args
      return get_default songname, args unless has_ivar? songname
      ivar = get_ivar songname
      return ivar unless ivar.kind_of? SongQueue
      play_from_queue ivar, songname
    end

    def prepare_song(songname, args, &block)
      set_ivar songname, *args
    end

    def prepare_song_queue(songname, args, &block)
      set_ivar songname, SongQueue.new(args)
    end

    def invocations(songname)
      played_songs[songname]
    end

  private

    def played_songs
      @played_songs ||= Hash.new do |hash, songname|
        must_know songname
        hash[songname] = []
      end
    end

    def get_default(songname, args)
      songs[songname].default instance, args do
        raise UnpreparedMethodError, "#{songname} has been invoked without being told how to behave"
      end
    end

    def play_from_queue(queue, songname)
      result = queue.dequeue
      unset_ivar songname if queue.empty?
      result
    end

    def must_know(songname)
      return if songs.has_key? songname
      known_songs = songs.keys.map(&:to_s).map(&:inspect).join ', '
      raise UnknownSong, "doesn't know \"#{songname}\", only knows #{known_songs}"
    end

    def has_ivar?(songname)
      instance.instance_variable_defined? "@#{songname}"
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

