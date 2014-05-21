require 'surrogate/argument_errorizer'

describe Surrogate::ArgumentErrorizer do
  let(:meth_name) { :some_name }

  describe 'match!' do
    it 'raises an argument error if the arguments do not match' do
      expect { described_class.new(meth_name, ->(){}).match! 1 }.to raise_error ArgumentError
      expect { described_class.new(meth_name, ->(a){}).match! }.to raise_error ArgumentError
    end

    it 'does not raise any errors if the arguments do match' do
      described_class.new(meth_name, ->(){}).match!
    end

    it 'does not execute the actual lambda' do
      described_class.new(meth_name, ->{ raise }).match!
    end

    it 'cares about required, optional, and block arguments' do
      errorizer = described_class.new meth_name, ->(a, b=1, c, &d){}
      expect { errorizer.match!   }.to raise_error ArgumentError
      expect { errorizer.match! 1 }.to raise_error ArgumentError
      errorizer.match! 1, 2
      errorizer.match! 1, 2, 3
      expect { errorizer.match! 1, 2, 3, 4 }.to raise_error ArgumentError

      errorizer = described_class.new meth_name, ->(a, b=1, *c, d, &e){}
      errorizer.match! *1..10
    end

    it 'does not care whether the block was provided' do
      described_class.new(meth_name, ->(&b){}).match!
    end
  end

  def assert_message(the_lambda, args, message)
    expect { described_class.new(meth_name, the_lambda).match! *args }
      .to raise_error ArgumentError, message
  end

  it 'has useful error messages' do
    assert_message ->(){},                           [1],   "wrong number of arguments (1 for 0) in #{meth_name}()"
    assert_message ->(a){},                          [],    "wrong number of arguments (0 for 1) in #{meth_name}(a)"
    assert_message ->(a){},                          [],    "wrong number of arguments (0 for 1) in #{meth_name}(a)"
    assert_message ->(a=1){},                        [1,2], "wrong number of arguments (2 for 0..1) in #{meth_name}(a='?')"
    assert_message ->(a, *b){},                      [],    "wrong number of arguments (0 for 1+) in #{meth_name}(a, *b)"
    assert_message ->(a, *b, &c){},                  [],    "wrong number of arguments (0 for 1+) in #{meth_name}(a, *b, &c)"
    assert_message ->(a, b, c=1, d=1, *e, f, &g){},  [],    "wrong number of arguments (0 for 3+) in #{meth_name}(a, b, c='?', d='?', *e, f, &g)"
  end

  it 'raises an ArgumentError if initialized with a non lambda/method' do
    def self.some_method() end
    described_class.new 'some_name', method(:some_method)
    described_class.new 'some_name', lambda {}
    expect { described_class.new 'some_name', Proc.new {} }.to raise_error ArgumentError, 'Expected a lambda or method, got a Proc'
    expect { described_class.new 'some_name', 'abc' }.to raise_error ArgumentError, 'Expected a lambda or method, got a String'
  end
end
