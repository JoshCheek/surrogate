require 'mockingbird'

describe 'singing in the block' do
  it 'sings to the class' do
    mocked_class = Class.new do
      Mockingbird.song_for self do
        sing :find, default: 123
      end
    end

    mocked_class.find.should == 123

    pending 'need to find something better than clone' do
      mocked = mocked_class.clone
      mocked.will_find 456
      mocked.find.should == 456
      mocked_class.find.should == 123
    end
  end
end
