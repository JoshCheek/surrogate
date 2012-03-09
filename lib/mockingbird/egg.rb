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

