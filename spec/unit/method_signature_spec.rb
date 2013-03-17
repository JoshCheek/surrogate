require 'surrogate/method_signature'

describe Surrogate::MethodSignature do
  def sig_for(klass, method_name)
    described_class.new method_name,
                        klass.instance_method(method_name).parameters
  end

  it 'knows the param_names' do
    klass = Class.new { def meth(w, x=1, *y, &z) end }
    sig_for(klass, :meth).param_names.should == [:w, :x, :y, :z]
  end

  it 'knows the param_types' do
    klass = Class.new { def meth(v, w=1, *x, y, &z) end }
    sig_for(klass, :meth).param_types.should == [:req, :opt, :rest, :req, :block]
    # here we could put Ruby 2.0 specific stuff if we really wanted to
  end

  it 'is reflectable when there are both types and names' do
    klass = Class.new { def meth(a) end }
    sig_for(klass, :meth).should be_reflectable
    sig_for(klass, :kind_of?).should_not be_reflectable
  end

  it 'inspects to something that looks like the method signature' do
    klass = Class.new { def meth(v, w=1, *x, y, &z) end }
    sig_for(klass, :meth).inspect.should == "meth(v, w='?', *x, y, &z)"
    # here we could put Ruby 2.0 specific stuff if we really wanted to
  end
end
