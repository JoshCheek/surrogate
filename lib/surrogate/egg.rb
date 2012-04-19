class Surrogate
  class Egg
    attr_accessor :klass

    def initialize(klass)
      self.klass = klass
      sings_songs
    end

    def hatch(instance)
      Bird.new instance, self
    end

    def sings_songs
      klass.singleton_class.send :define_method, :song, &method(:song)
    end

    def song(songname, options={}, block)
      add_song_methods_for songname
      songs[songname] = Options.new options, block
    end

    def songs
      @songs ||= {}
    end

    def song_names
      songs.keys - [:initialize]
    end

    # here we need to find better domain terminology
    def add_song_methods_for(songname)
      klass.send :define_method, songname do |*args, &block|
        @surrogate.play_song songname, args, &block
      end

      # verbs
      klass.send :define_method, "will_#{songname}" do |*args, &block|
        @surrogate.prepare_song songname, args, &block
        self
      end

      klass.send :define_method, "will_#{songname}_queue" do |*args, &block|
        @surrogate.prepare_song_queue songname, args, &block
        self
      end

      # nouns
      klass.send :alias_method, "will_have_#{songname}", "will_#{songname}"
      klass.send :alias_method, "will_have_#{songname}_queue", "will_#{songname}_queue"
    end
  end
end

