require 'mockingbird'

describe 'singing out of a block' do
  describe 'declaring the behaviour' do
  end

  context 'the api method' do
    let(:mocked_class) { Mockingbird.song_for Class.new }

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
  end
end
