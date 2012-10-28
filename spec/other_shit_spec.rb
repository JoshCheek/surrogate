require 'spec_helper'

describe '.last_instance' do
  let(:klass) { Surrogate.endow Class.new }
  def with_inspect(n, instance)
    instance.singleton_class.class_eval do
      define_method(:inspect) { "#<INSTANCE #{n}>" }
    end
    instance
  end

  it 'returns nil when it was not instantiated' do
    klass.last_instance.should be_nil
  end

  it 'returns the last instance that was created' do
    instance = klass.new
    klass.last_instance.should equal instance
  end

  specify 'threads do not fuck it up' do
    fiber = Fiber.new do
      fiber_instance = with_inspect 1, klass.new
      Fiber.yield
      klass.last_instance.should equal fiber_instance
    end
    instance = with_inspect 2, klass.new
    fiber.resume
    klass.last_instance.should equal instance
    fiber.resume
  end

  specify 'multiple surrogates do not fuck it up' do
    klass1 = Surrogate.endow Class.new
    klass2 = Surrogate.endow Class.new
    instance1 = with_inspect 1, klass1.new
    instance2 = with_inspect 2, klass2.new
    klass1.last_instance.should equal instance1
    klass2.last_instance.should equal instance2
  end

  context 'on a clone' do
    it 'the clone returns the last instance' do
      clone = klass.clone
      instance = clone.new
      clone.last_instance.should == instance
    end

    it 'the original surrogate does not return the last instance' do
      klass.clone.new
      klass.last_instance.should be_nil
    end
  end
end


describe 'inspect methods' do
  context 'on the class' do
    context 'when anonymous identifies itself as an anonymous surrogate and lists three each of class and instance methods, alphabetically' do
      example 'no class methods' do
        Surrogate.endow(Class.new).inspect.should == 'AnonymousSurrogate(no api)'
      end

      example 'one class method' do
        klass = Surrogate.endow(Class.new) { define :cmeth }
        klass.inspect.should == 'AnonymousSurrogate(Class: cmeth)'
      end

      example 'more than three class methods' do
        Surrogate.endow(Class.new) do
          define :cmethd
          define :cmethc
          define :cmetha
          define :cmethb
        end.inspect.should == 'AnonymousSurrogate(Class: cmetha cmethb cmethc ...)'
      end

      example 'one instance method' do
        Surrogate.endow(Class.new).define(:imeth).inspect.should == 'AnonymousSurrogate(Instance: imeth)'
      end

      example 'more than three instance methods' do
        klass = Surrogate.endow Class.new
        klass.define :imethd
        klass.define :imethc
        klass.define :imetha
        klass.define :imethb
        klass.inspect.should == 'AnonymousSurrogate(Instance: imetha imethb imethc ...)'
      end

      example 'one of each' do
        Surrogate.endow(Class.new) { define :cmeth }.define(:imeth).inspect.should == 'AnonymousSurrogate(Class: cmeth, Instance: imeth)'
      end

      example 'more than three of each' do
        klass = Surrogate.endow Class.new do
          define :cmethd
          define :cmethc
          define :cmetha
          define :cmethb
        end
        klass.define :imethd
        klass.define :imethc
        klass.define :imetha
        klass.define :imethb
        klass.inspect.should == 'AnonymousSurrogate(Class: cmetha cmethb cmethc ..., Instance: imetha imethb imethc ...)'
      end
    end

    context 'when the surrogate has a name (e.g. assigned to a constant)' do
      it 'inspects to the name of the constant' do
        klass = Surrogate.endow(Class.new)
        self.class.const_set 'Abc', klass
        klass.inspect.should == self.class.name << '::Abc'
      end
    end
  end

  context 'on a clone of the surrogate' do
    context 'when the surrogate has a name (e.g. assigned to a constant)' do
      it 'inspects to the name of the constant, cloned' do
        klass = Surrogate.endow(Class.new)
        self.class.const_set 'Abc', klass
        klass.clone.inspect.should == self.class.name << '::Abc.clone'
      end
    end
  end

  # eventually these should maybe show unique state (expectations/invocations) but for now, this is better than what was there before
  context 'on the instance' do
    context 'when anonymous' do
      it 'identifies itself as an anonymous surrogate and lists three of its methods, alphabetically' do
        klass = Surrogate.endow Class.new
        klass.new.inspect.should == '#<AnonymousSurrogate: no api>'
        klass.define :imethb
        klass.new.inspect.should == '#<AnonymousSurrogate: imethb>'
        klass.define :imetha
        klass.define :imethd
        klass.new.inspect.should == '#<AnonymousSurrogate: imetha imethb imethd>'
        klass.define :imethc
        klass.new.inspect.should == '#<AnonymousSurrogate: imetha imethb imethc ...>'
      end
    end

    context 'when a clone of an anonymous surrogate' do
      it 'looks the same as any other anonymous surrogate' do
        klass = Surrogate.endow Class.new
        klass.new.inspect.should == '#<AnonymousSurrogate: no api>'
      end
    end

    context 'when its class has a name (e.g. for a constant)' do
      it 'identifies itself as an instance of the constant and lists three of its methods, alphabetically' do
        klass = Surrogate.endow Class.new
        self.class.const_set 'Abc', klass
        klass.stub name: 'Abc'
        klass.new.inspect.should == "#<Abc: no api>"
        klass.define :imethb
        klass.new.inspect.should == "#<Abc: imethb>"
        klass.define :imetha
        klass.define :imethd
        klass.new.inspect.should == "#<Abc: imetha imethb imethd>"
        klass.define :imethc
        klass.new.inspect.should == "#<Abc: imetha imethb imethc ...>"
      end
    end
  end

  context 'on an instance of a surrogate clone' do
    context 'when its class has a name (e.g. for a constant)' do
      it 'identifies itself as an instance of the clone of the constant and lists three of its methods, alphabetically' do
        klass = Surrogate.endow Class.new
        self.class.const_set 'Abc', klass
        klass.clone.new.inspect.should == "#<#{self.class}::Abc.clone: no api>"
        klass.define :imethb
        klass.clone.new.inspect.should == "#<#{self.class}::Abc.clone: imethb>"
        klass.define :imetha
        klass.define :imethd
        klass.clone.new.inspect.should == "#<#{self.class}::Abc.clone: imetha imethb imethd>"
        klass.define :imethc
        klass.clone.new.inspect.should == "#<#{self.class}::Abc.clone: imetha imethb imethc ...>"
      end
    end
  end
end

describe '.factory' do
  it 'allows you to initialize the values of the returned mock' do
    klass = Surrogate.endow(Class.new).define(:a){'a'}.define(:b){'b'}
    klass.factory(a: 'A').a.should == 'A'
    klass.factory(a: 'A').b.should == 'b'
    klass.new.a.should == 'a'
  end

  it 'can be turned off at the class level with Surrogate.endow self build_mock: false' do
    klass = Surrogate.endow(Class.new, factory: false).define(:a) { 'a' }
    expect { klass.factory a: 'A' }.to raise_error NoMethodError
  end

  it 'can be given a different method name by passing the name to the endower' do
    klass = Surrogate.endow(Class.new, factory: :construct).define(:a) { 'a' }
    expect { klass.factory a: 'A' }.to raise_error NoMethodError
    klass.construct(a: 'A').a.should == 'A'
  end

  it 'retains its setting on clones' do
    clone = Surrogate.endow(Class.new, factory: :construct).define(:a){'a'}.clone
    expect { clone.factory a: 'A' }.to raise_error NoMethodError
    clone.construct(a: 'A').a.should == 'A'
    clone.new.a.should == 'a'
  end

  context 'when the initialize method can be invoked without args' do
    let(:klass)    { Surrogate.endow(Class.new).define(:initialize) { } }
    let!(:instance) { klass.factory }

    it 'is invoked' do
      instance.was initialized_with no_args
    end

    specify 'the instance is recorded as the last instance' do
      klass.last_instance.should == instance
    end
  end

  context 'when the initialize method cannot be invoked without args' do
    let(:klass)    { Surrogate.endow(Class.new).define(:initialize) {|arg|} }
    let!(:instance) { klass.factory }

    it 'is invoked' do
      instance.was_not told_to :initialize
    end

    specify 'the instance is recorded as the last instance' do
      klass.last_instance.should == instance
    end
  end
end
