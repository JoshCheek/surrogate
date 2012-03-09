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

