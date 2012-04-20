require 'spec_helper'

describe Surrogate::ApiComparer do

  def set_assertion(set, expectations)
    expectations[:include].each { |meth| set.should include meth }
    expectations[:exclude].each { |meth| set.should_not include meth }
  end


  describe 'its knowlege about the surrogate' do

    let :surrogate do
      parent = Class.new do
        def inherited_instance_meth()end
        def self.inherited_class_meth()end
      end

      Class.new parent do
        Surrogate.endow self do
          define :api_class_meth
          def class_meth()end
        end
        define :api_instance_meth
        def instance_meth()end
      end
    end

    let(:comparer) { described_class.new surrogate, Class.new }

    it "knows the surrogate's instance level api methods" do
      comparer.surrogate_methods[:instance][:api].should == Set[:api_instance_meth]
    end

    it "knows the surrogate's inherited instance methods" do
      set_assertion comparer.surrogate_methods[:instance][:inherited],
        include: [:inherited_instance_meth],
        exclude: [:api_instance_meth, :instance_meth, :class_meth, :inherited_class_meth, :api_class_meth]
    end

    it "knows the surrogate's other instance methods" do
      set_assertion comparer.surrogate_methods[:instance][:other],
        include: [:instance_meth],
        exclude: [:inherited_instance_meth, :api_instance_meth, :class_meth, :inherited_class_meth, :api_class_meth]
    end

    it "knows the surrogate's class level api methods" do
      comparer.surrogate_methods[:class][:api].should == Set[:api_class_meth]
    end

    it "knows the surrogate's inherited class methods" do
      # show new explicitly as we override it in lib
      set_assertion comparer.surrogate_methods[:class][:inherited],
        include: [:inherited_class_meth, :new],
        exclude: [:api_instance_meth, :instance_meth, :class_meth, :inherited_instance_meth, :api_class_meth]
    end

    it "knows the surrogate's other class methods" do
      # show new explicitly as we override it in lib
      set_assertion comparer.surrogate_methods[:class][:other],
        include: [:class_meth],
        exclude: [:new, :api_instance_meth, :instance_meth, :inherited_instance_meth, :api_class_meth, :inherited_class_meth]
    end
  end


  describe 'its knowledge about the other object' do
    let(:surrogate) { Surrogate.endow Class.new }

    let :actual do
      parent = Class.new { def self.inherited_class_meth()end; def inherited_instance_meth()end }
      Class.new(parent) { def self.class_meth()end; def instance_meth()end }
    end

    let(:comparer) { described_class.new surrogate, actual }

    it "knows the object's inherited instance methods" do
      set_assertion comparer.actual_methods[:instance][:inherited],
        include: [:inherited_instance_meth],
        exclude: [:inherited_class_meth, :class_meth, :instance_meth]
    end

    it "knows the objects other instance methods" do
      comparer.actual_methods[:instance][:other].should == Set[:instance_meth]
    end

    it "knows the object's inherited class methods" do
      set_assertion comparer.actual_methods[:class][:inherited],
        include: [:inherited_class_meth],
        exclude: [:inherited_instance_meth, :class_meth, :instance_meth]
    end

    it "knows the object's other class methods" do
      comparer.actual_methods[:class][:other].should == Set[:class_meth]
    end
  end


  describe '#compare' do
    let(:parent) { Class.new { def inherited_instance_not_on_surrogate()end; def self.inherited_class_not_on_surrogate()end } }

    let :actual do
      Class.new parent do
        def instance_not_on_surrogate()end
        def self.class_not_on_surrogate()end
        def instance_meth_on_both()end
        def self.class_meth_on_both()end
      end
    end

    let :surrogate do
      Class.new do
        Surrogate.endow(self) { define :class_not_on_actual }
        define :instance_not_on_actual
        def instance_meth_on_both()end
        def self.class_meth_on_both()end
      end
    end

    let(:comparer) { described_class.new surrogate, actual }

    it 'tells me about instance methods on actual that are not on surrogate' do
      comparer.compare[:instance][:not_on_surrogate].should == Set[:instance_not_on_surrogate, :inherited_instance_not_on_surrogate, :instance_meth_on_both]
    end

    it 'tells me about class methods on actual that are not on surrogate' do
      comparer.compare[:class][:not_on_surrogate].should == Set[:class_not_on_surrogate, :inherited_class_not_on_surrogate, :class_meth_on_both]
    end

    it 'tells me about api instance methods on surrogate that are not on actual' do
      comparer.compare[:instance][:not_on_actual].should == Set[:instance_not_on_actual]
    end

    it 'tells me about api class methods on surrogate that are not on actual' do
      comparer.compare[:class][:not_on_actual].should == Set[:class_not_on_actual]
    end
  end
end
