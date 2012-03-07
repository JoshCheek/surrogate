require 'cobbler'

describe 'cobbling out of a block' do
  describe 'declaring the behaviour' do
  end

  context 'the api method' do
    let(:cobbled_class) { Cobbler.cobble Class.new }

    it 'raises an UnpreparedMethodError when it has no default' do
      cobbled_class.cobble :meth
      expect { cobbled_class.new.meth }.to raise_error(Cobbler::UnpreparedMethodError, /meth/)
    end

    it 'considers ivars of the same name to be its default' do
      cobbled_class.cobble :meth
      cobbled = cobbled_class.new
      cobbled.instance_variable_set :@meth, 123
      cobbled.meth.should == 123
    end

    it 'reverts to the :default option if invoked and having no ivar' do
      cobbled_class.cobble :meth, default: 123
      cobbled = cobbled_class.new
      cobbled.instance_variable_get(:@meth).should be_nil
      cobbled.meth.should == 123
    end

    it 'sets the ivar to the :default! option if present' do
      cobbled_class.cobble :meth, default!: 123
      cobbled = cobbled_class.new
      cobbled.instance_variable_get(:@meth).should == 123
    end
  end
end
