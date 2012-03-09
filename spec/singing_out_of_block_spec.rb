require 'mockingbird'

describe 'singing out of a block' do
  let(:mocked_class) { Mockingbird.song_for Class.new }

  # are there parts of songs like "setup", "body", "conclusion"?
  # that would make it easier to talk about these, as the descriptions I'm using are obtuse

  describe 'declaring the behaviour' do
    before     { mocked_class.sing :wink }
    let(:mock) { mocked_class.new }

    def self.shared_for_song_named_wink(name)
      it 'defines will_<song> which overrides the default' do
        mock1 = mocked_class.new
        mock2 = mocked_class.new
        mock1.will_wink :quickly
        mock2.will_wink :slowly
        mock1.wink.should == :quickly
        mock2.wink.should == :slowly
        mock1.wink.should == :quickly
      end
    end

    shared_for_song_named_wink("will_<song>") { |mock| mock.will_wink }
    # shared_setter("will_<song>") { |mock| mock.will_wink }

    context 'will_<song>_queue creates a queue of things to find then returns to normal behaviour' do
      specify 'when there is no default' do
        mock = mocked_class.new
        mock.will_wink_queue :quickly, :slowly
        mock.wink.should == :quickly
        mock.wink.should == :slowly
        expect { mock.wink }.to raise_error Mockingbird::UnpreparedMethodError
      end

      specify 'when there is a default' do
        mocked_class = Mockingbird.song_for(Class.new)
        mocked_class.sing :connect, default: :default
        mock = mocked_class.new
        mock.will_connect_queue 1, 2
        mock.connect.should == 1
        mock.connect.should == 2
        mock.connect.should == :default
      end

      specify 'when there is a default!' do
        mocked_class = Mockingbird.song_for(Class.new)
        mocked_class.sing :connect, default!: :default
        mock = mocked_class.new
        mock.will_connect_queue 1, 2
        mock.connect.should == 1
        mock.connect.should == 2
        mock.instance_variable_get(:@connect).should == :default
      end
    end
  end



  context 'the song' do
    it 'takes any number of arguments' do
      mocked_class.sing :meth, default: 1
      mocked_class.new.meth.should == 1
      mocked_class.new.meth(1).should == 1
      mocked_class.new.meth(1, 2).should == 1
    end

    it 'raises an UnpreparedMethodError when it has no default' do
      mocked_class.sing :meth
      expect { mocked_class.new.meth }.to raise_error(Mockingbird::UnpreparedMethodError, /meth/)
    end

    it 'considers ivars of the same name to be its default' do
      mocked_class.sing :meth
      mocked = mocked_class.new
      mocked.instance_variable_set :@meth, 123
      mocked.meth.should == 123
    end

    it 'reverts to the :default option if invoked and having no ivar' do
      mocked_class.sing :meth, default: 123
      mocked = mocked_class.new
      mocked.instance_variable_get(:@meth).should be_nil
      mocked.meth.should == 123
    end

    it 'sets the ivar to the :default! option if present' do
      mocked_class.sing :meth, default!: 123
      mocked = mocked_class.new
      mocked.instance_variable_get(:@meth).should == 123
    end

    describe 'it takes a block whos return value will be used as the default' do
      specify 'the block is instance evaled' do
        mocked_class.sing(:meth) { self }
        instance = mocked_class.new
        instance.meth.should equal instance
      end

      specify 'arguments passed to the method will be passed to the block' do
        mocked_class.sing(:meth) { |*args| args }
        instance = mocked_class.new
        instance.meth(1).should == [1]
        instance.meth(1, 2).should == [1, 2]
      end
    end
  end
end
