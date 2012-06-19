require 'spec_helper'


describe Surrogate::RSpec::AbstractFailureMessage::ArgsInspector, 'argument inspection' do

  describe 'individual argument inspection inspection' do
    it 'inspects non RSpec matchers as their default inspection' do
      described_class.inspect_argument("1").should == '"1"'
      described_class.inspect_argument(1).should == "1"
      described_class.inspect_argument([/a/]).should == "[/a/]"
    end

    it 'inspects rspec matchers' do
      described_class.inspect_argument(no_args).should == 'no args'
      described_class.inspect_argument(hash_including abc: 123).should == 'hash_including(:abc=>123)'
    end
  end


  describe 'multiple argument inspection' do
    def inspect_args(args)
      described_class.inspect Surrogate::Invocation.new(args)
    end

    it "wraps individual arguments in `'" do
      inspect_args([/a/]).should == "`/a/'"
    end

    it "joins arguments with commas" do
      inspect_args(['x', no_args]).should == "`\"x\", no args'"
    end

    it 'returns no_args when the array is empty' do
      inspect_args([]).should == "`no args'"
    end
  end
end
