require 'spec_helper'

describe 'RSpec matchers', 'have_been_told_to(...).with { |block| }' do

  let(:dir)      { Surrogate.endow(Class.new) { define(:chdir) { nil }}}
  let(:dir_path) { '/some/dir/path' }

  it 'fails if no submitted_blocks were found' do
    dir.should_not have_been_told_to(:chdir).with(dir_path) { |block|
      block.before { raise 'this should not be executed' }
    }

    dir.chdir dir_path

    dir.should_not have_been_told_to(:chdir).with(dir_path) { |block|
      block.before { raise 'this should not be executed' }
    }

    dir.chdir(dir_path) { }
    dir.should have_been_told_to(:chdir).with(dir_path) { }
  end

  # TODO: Needs to take into account the fact that when there are multiple invocations,
  # the before/after blocks will be called multiple times

  it "fails if the arguments don't match, even if the block does" do
    dir.chdir(dir_path) { }
    dir.should_not have_been_told_to(:chdir).with(dir_path.reverse) { }
    dir.should     have_been_told_to(:chdir).with(dir_path) { }
  end


  it 'yields a test_block that can make assertions' do
    dir.chdir(dir_path) { }
    block_yielded = nil
    dir.should have_been_told_to(:chdir).with(dir_path) { |block|
      block_yielded = block
    }
    block_yielded.should be
  end

  describe 'the .returns assertion' do
    it "passes if the submitted_block does return the value" do
      dir.chdir(dir_path) { 1 }
      dir.should_not have_been_told_to(:chdir).with(dir_path) { |block| block.returns 2 }
      dir.should     have_been_told_to(:chdir).with(dir_path) { |block| block.returns 1 }
    end

    specify "if given a block, it passes the submitted_block's return value to it" do
      dir.chdir(dir_path) { 1 }
      dir.should_not have_been_told_to(:chdir).with(dir_path) { |block| block.returns { 2 } }
      dir.should     have_been_told_to(:chdir).with(dir_path) { |block| block.returns { 1 } }
    end
  end


  let(:file)      { Surrogate.endow(Class.new) { define(:write) { true }}}
  let(:file_name) { 'some_file_name.ext' }
  let(:file_body) { 'some file body' }

  describe 'the .before and .after hooks' do
    specify "take blocks which it will evaluate before/after invoking the submitted_block" do
      dir.chdir(dir_path) { file.write file_name, file_body }
      dir.should have_been_told_to(:chdir).with(dir_path) { |block|
        block.before { file.should_not have_been_told_to :write }
        block.after  { file.should     have_been_told_to :write }
      }
    end

    example "multiple invocations wrong number of times" do
      dir.chdir(dir_path) { file.write file_name, file_body }
      dir.chdir(dir_path) { file.write file_name, file_body }
      dir.should_not have_been_told_to(:chdir).times(1).with(dir_path) { |block|
        block.before { file.should_not have_been_told_to :write }
        block.after  { file.should     have_been_told_to :write }
      }
    end

    example "multiple invocations correct number of times" do
      dir.chdir(dir_path) { file.write file_name, file_body }
      dir.chdir(dir_path) { file.write file_name, file_body }
      dir.should have_been_told_to(:chdir).times(2).with(dir_path) { |block|
        block.before { file.should_not have_been_told_to :write }
        block.after  { file.should     have_been_told_to :write }
      }
    end
  end

  describe 'the .arity assertion' do
    it "takes a number corresponding to the arity of the block" do
      klass = Surrogate.endow(Class.new)
      klass.define(:meth) { self }
      klass.new.meth { |a|     }.should have_been_told_to(:meth).with { |b| b.arity  1 }
      klass.new.meth { |a,b|   }.should have_been_told_to(:meth).with { |b| b.arity  2 }
      klass.new.meth { |a,b,c| }.should have_been_told_to(:meth).with { |b| b.arity  3 }
      klass.new.meth { |*a|    }.should have_been_told_to(:meth).with { |b| b.arity -1 }
      expect {
        klass.new.meth { |a|   }.should have_been_told_to(:meth).with { |b| b.arity 123 }
      }.to raise_error RSpec::Expectations::ExpectationNotMetError
    end
  end

  describe 'the .raising assertion' do
    it "is the same as RSpec's raise_error interface" do
      pending "I'll deal with this shit when I'm not so tired"
    end
  end
end
