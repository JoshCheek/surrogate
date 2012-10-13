require 'spec_helper'

# these all need error messages
describe 'RSpec matchers', 'have_been_told_to(...).with { |block| }' do

  def fails(&block)
    expect { block.call }.to raise_error RSpec::Expectations::ExpectationNotMetError
  end

  let(:dir)      { Surrogate.endow(Class.new) { define(:chdir) { |dir_path| nil }}}
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

  it "fails if the block's arguments don't match" do
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

    specify "if given a block, it passes the return value to it for making assertions" do
      dir.chdir(dir_path) { 1 }

      dir.should_not have_been_told_to(:chdir).with(dir_path) { |block|
        block.returns { |result| result.should == 2 }
      }

      dir.should have_been_told_to(:chdir).with(dir_path) { |block|
        block.returns { |result| result.should == 1 }
      }
    end
  end


  let(:file)      { Surrogate.endow(Class.new) { define(:write) { |name, body| true }}}
  let(:file_name) { 'some_file_name.ext' }
  let(:file_body) { 'some file body' }

  # reword this a bit
  describe 'the .before and .after hooks' do
    specify "take blocks which it will evaluate before/after invoking the submitted_block" do
      dir.chdir(dir_path) { file.write file_name, file_body }
      dir.should have_been_told_to(:chdir).with(dir_path) { |block|
        block.before { file.should_not have_been_told_to :write }
        block.after  { file.should     have_been_told_to :write }
      }
    end

    example "example: multiple invocations wrong number of times" do
      dir.chdir(dir_path) { file.write file_name, file_body }
      dir.chdir(dir_path) { file.write file_name, file_body }
      dir.should_not have_been_told_to(:chdir).times(1).with(dir_path) { |block|
        block.before { file.should_not have_been_told_to :write }
        block.after  { file.should     have_been_told_to :write }
      }
    end

    example "example: multiple invocations correct number of times" do
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
      fails { klass.new.meth { |a|   }.should have_been_told_to(:meth).with { |b| b.arity 123 } }
    end
  end

  describe ".call_with" do
    it 'allows the user to provide arguments' do
      klass = Surrogate.endow(Class.new).define(:add) { self }
      instance = klass.new
      instance.add { |a, b, &c| a + b + c.call }
      instance.should have_been_told_to(:add).with { |block|
        block.call_with(1, 2) { 3 }
        block.returns 6
      }

      instance = klass.new
      i = 10
      instance.add { |n, &b| i += n + b.call }
      instance.should have_been_told_to(:add).with { |block|
        block.call_with(3) { 4 }
        block.after { i.should == 17 }
      }
    end
  end

  describe ".raising is like RSpec's raise_error interface" do
    let(:klass) { Surrogate.endow(Class.new).define(:meth) { |&block| self } }

    it 'fails when an exception is expected but not raised' do
      fails { klass.new.meth { }.was told_to(:meth).with { |b| b.raising "not whatever" } }
    end

    it 'fails when an exception is raised but not expected' do
      fails { klass.new.meth { raise }.was told_to(:meth).with { |b| } }
    end

    # expect { raise "hello world" }.to raise_error "hello world"
    it 'can take a string which must match the message' do
              klass.new.meth { raise "whatever" }.was told_to(:meth).with { |b| b.raising "whatever" }
      fails { klass.new.meth { raise "whatever" }.was told_to(:meth).with { |b| b.raising "not whatever" } }
    end

    # expect { raise "hello world" }.to raise_error /hello/
    it 'can take a regex which must match the message' do
              klass.new.meth { raise "whatever" }.was told_to(:meth).with { |b| b.raising /whatev/ }
      fails { klass.new.meth { raise "whatever" }.was told_to(:meth).with { |b| b.raising /not a match/ } }
    end

    # expect { raise ArgumentError }.to raise_error ArgumentError
    it 'can take an exception class which must be raised' do
              klass.new.meth { raise ArgumentError, 'some message' }.was told_to(:meth).with { |b| b.raising ArgumentError }
      fails { klass.new.meth { raise ArgumentError, 'some message' }.was told_to(:meth).with { |b| b.raising RuntimeError } }
    end

    # expect { raise ArgumentError, "whatever" }.to raise_error ArgumentError, "whatever"
    it 'can take an exception class and string' do
              klass.new.meth { raise ArgumentError, 'whatever' }.was told_to(:meth).with { |b| b.raising ArgumentError, 'whatever' }
      fails { klass.new.meth { raise RuntimeError,  'whatever' }.was told_to(:meth).with { |b| b.raising ArgumentError, 'whatever' } }
      fails { klass.new.meth { raise ArgumentError, 'whatever' }.was told_to(:meth).with { |b| b.raising ArgumentError, 'not whatever' } }
    end

    # expect { raise ArgumentError, 'abc' }.to raise_error ArgumentError, /abc/
    it 'can take an exception class and regex' do
              klass.new.meth { raise ArgumentError, "whatever" }.was told_to(:meth).with { |b| b.raising ArgumentError, /what/ }
      fails { klass.new.meth { raise RuntimeError,  "whatever" }.was told_to(:meth).with { |b| b.raising ArgumentError, /whatever/ } }
      fails { klass.new.meth { raise ArgumentError, "whatever" }.was told_to(:meth).with { |b| b.raising ArgumentError, /not a match/ } }
    end

    it 'raises an error when given anything else' do
      bad_args = -> &block { expect { block.call }.to raise_error ArgumentError, /not valid arguments/ }
      bad_args.call { klass.new.meth {}.was told_to(:meth).with { |b| b.raising Class             } } # not an exception
      bad_args.call { klass.new.meth {}.was told_to(:meth).with { |b| b.raising []                } } # not a string/regex
      bad_args.call { klass.new.meth {}.was told_to(:meth).with { |b| b.raising ArgumentError, [] } } # 2nd param is not a string/regex
    end
  end
end
