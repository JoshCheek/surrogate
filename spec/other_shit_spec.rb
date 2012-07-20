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
