class Mockingbird
  module RSpec
    module MessagesFor
      ::RSpec::Matchers.define :be_substitutable_for do |original_class|

        def has_same_instance_methods?(original_class, mocked_class)
          @songs = mocked_class.song_names
          if @songs.empty?
            inherited_methods = mocked_class.instance_methods - mocked_class.instance_methods(false)
            inherited_methods.sort == (original_class.instance_methods - [:new]).sort
          else
            @songs_on_original_class = (original_class.instance_methods & @songs) 
            @songs_on_original_class.sort == @songs.sort
          end
        end
        
        def has_same_class_methods?(original_class, mocked_class)
          has_same_instance_methods?(original_class.singleton_class, mocked_class.singleton_class)
        end

        match do |mocked_class|
          has_same_instance_methods?(original_class, mocked_class) &&
            has_same_class_methods?(original_class, mocked_class)
        end

        failure_message_for_should do
          "expected #{@songs}, got #{@songs_on_original_class}"
        end

        failure_message_for_should_not do
          "expected #{@songs} to not equal #{@songs_on_original_class}"
        end
      end
    end
  end
end

