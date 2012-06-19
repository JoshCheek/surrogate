require 'spec_helper'

inspector = Surrogate::RSpec::AbstractFailureMessage::ArgsInspector

describe inspector, 'argument inspection' do

  describe 'individual argument inspection inspection' do
    it 'inspects non RSpec matchers as their default inspection' do
      inspector.inspect_argument("1").should == '"1"'
      inspector.inspect_argument(1).should == "1"
      inspector.inspect_argument([/a/]).should == "[/a/]"
    end

    it 'inspects rspec matchers' do
      inspector.inspect_argument(no_args).should == 'no args'
      inspector.inspect_argument(hash_including abc: 123).should == 'hash_including(:abc=>123)'
    end
  end


  describe 'multiple argument inspection' do
    it "wraps individual arguments in `'" do
      inspector.inspect([/a/]).should == "`/a/'"
    end

    it "joins arguments with commas" do
      inspector.inspect(['x', no_args]).should == "`\"x\", no args'"
    end

    it 'returns no_args when the array is empty' do
      inspector.inspect([]).should == "`no args'"
    end
  end
end
