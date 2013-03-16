require 'spec_helper'
require 'surrogate/api_comparer2'


class Surrogate
  describe ApiComparer2 do
    ::Kernel.module_eval do
      def public_method_on_every_object()    1 end
      def private_method_on_every_object()   2 end
      def protected_method_on_every_object() 3 end
      private   :private_method_on_every_object
      protected :protected_method_on_every_object
    end

    %w[ m_with_params
        cm_inherited_on_actual
        im_inherited_on_actual
        cm_inherited_on_surrogate
        im_inherited_on_surrogate
        cm_on_surrogate
        im_on_surrogate
        cm_on_actual
        im_on_actual
        cmapi
        imapi
        not_on_surrogate
        not_on_actual
        m_with_type_mismatch
        m_with_matching_names
        m_with_mismatching_names
    ].map(&:intern).each do |name|
      define_method name do
        comparison.all_methods.find { |method| method.name == name }
      end
    end

    let(:surrogate) do
      surrogate_superclass = Class.new do
        def self.cm_inherited_on_surrogate() end
        def im_inherited_on_surrogate() end
      end
      Class.new surrogate_superclass do
        Surrogate.endow self do
          define(:cmapi)
        end
        define(:imapi)
        def m_with_params(sreq, sopt=1, *srest, &sblock) end
        def self.cm_on_surrogate() end
        def im_on_surrogate() end
        def not_on_actual() end
        def m_with_type_mismatch(arg) end
        def m_with_matching_names(a, b=1, *c, &d) end
        def m_with_mismatching_names(sa, sb=1, *sc, &sd) end
      end
    end

    let(:actual) do
      actual_superclass = Class.new do
        def self.cm_inherited_on_actual() end
        def im_inherited_on_actual() end
      end
      Class.new actual_superclass do
        def m_with_params(areq, aopt=1, *arest, &ablock) end
        def self.cm_on_actual() end
        def im_on_actual() end
        def not_on_surrogate() end
        def m_with_type_mismatch(arg=1) end
        def m_with_matching_names(a, b=1, *c, &d) end
        def m_with_mismatching_names(aa, ab=1, *ac, &ad) end
      end
    end

    def comparison
      @comparison ||= described_class.new(surrogate: surrogate, actual: actual)
    end

    describe 'the methods it finds' do
      it 'know if they are on the surrogate' do
        cm_on_surrogate.should be_on_surrogate
        im_on_surrogate.should be_on_surrogate
        cm_on_actual.should_not be_on_surrogate
        im_on_actual.should_not be_on_surrogate
      end

      it 'know if they are on the actual' do
        cm_on_surrogate.should_not be_on_actual
        im_on_surrogate.should_not be_on_actual
        cm_on_actual.should        be_on_actual
        im_on_actual.should        be_on_actual
      end

      it 'know if they are an api method' do
        cm_on_surrogate.should_not  be_api_method
        im_on_surrogate.should_not  be_api_method
        cmapi.should                be_api_method
        imapi.should                be_api_method
        not_on_surrogate.should_not be_api_method
      end

      it 'know if they are inherited on the surrogate' do
        cm_inherited_on_surrogate.should be_inherited_on_surrogate
        im_inherited_on_surrogate.should be_inherited_on_surrogate
        cm_on_surrogate.should_not       be_inherited_on_surrogate
        im_on_surrogate.should_not       be_inherited_on_surrogate
        not_on_surrogate.should_not      be_inherited_on_surrogate
      end

      it 'know if they are inherited on the actual' do
        cm_inherited_on_actual.should be_inherited_on_actual
        im_inherited_on_actual.should be_inherited_on_actual
        cm_on_actual.should_not       be_inherited_on_actual
        im_on_actual.should_not       be_inherited_on_actual
        not_on_actual.should_not      be_inherited_on_actual
      end

      it 'know if they are a class method' do
        cm_on_surrogate.should be_a_class_method
        im_on_surrogate.should_not be_a_class_method
      end

      it 'know if they are an instance method' do
        cm_on_surrogate.should_not be_an_instance_method
        im_on_surrogate.should     be_an_instance_method
      end

      it 'knows the parameter names' do
        m_with_params.surrogate_parameters.param_names.should == [:sreq, :sopt, :srest, :sblock]
        m_with_params.actual_parameters.param_names.should    == [:areq, :aopt, :arest, :ablock]
        expect { not_on_surrogate.surrogate_parameters }.to raise_error NoMethodToCheckSignatureOf
        expect { not_on_actual.actual_parameters       }.to raise_error NoMethodToCheckSignatureOf
      end

      it 'knows the parameter types' do
        m_with_params.surrogate_parameters.param_types.should == [:req, :opt, :rest, :block]
        m_with_params.actual_parameters.param_types.should    == [:req, :opt, :rest, :block]
        expect { not_on_surrogate.surrogate_parameters }.to raise_error NoMethodToCheckSignatureOf
        expect { not_on_actual.actual_parameters       }.to raise_error NoMethodToCheckSignatureOf
      end

      it 'knows if the types match' do
        m_with_params.types_match?.should be_true
        m_with_type_mismatch.types_match?.should be_false
        not_on_surrogate.types_match?.should be_false
        not_on_actual.types_match?.should be_false
      end

      it 'knows if the names match' do
        m_with_matching_names.names_match?.should be_true
        m_with_mismatching_names.names_match?.should be_false
        not_on_surrogate.names_match?.should be_false
        not_on_actual.names_match?.should be_false
      end

      # do this if Ruby 2.0
      # it 'uses :req, :opt, :rest, :block, :key, and :keyrest'
    end

    describe 'the interesting interfaces' do
      specify "all_methods returns all the public methods found, minus the surrogate's helper methods" do
        def surrogate.helpah() end
        surrogate.singleton_class.surrogate_helper :helpah
        comparison.all_methods.map(&:name).should     include :public_method_on_every_object
        comparison.all_methods.map(&:name).should_not include :private_method_on_every_object
        comparison.all_methods.map(&:name).should_not include :protected_method_on_every_object
        comparison.all_methods.map(&:name).should_not include :helpah
      end

      example 'extra_instance_methods returns the instance methods on surrogate but not actual' do
        comparison.extra_instance_methods.should =~ [im_inherited_on_surrogate, imapi, im_on_surrogate, not_on_actual]
      end

      specify "extra_class_methods returns the class methods on surrogate but not actual" do
        comparison.extra_class_methods.should =~ [cm_inherited_on_surrogate, cm_on_surrogate, cmapi]
      end

      specify 'missing_instance_methods returns the instance methods on actual but not on surrogate' do
        comparison.missing_instance_methods.should =~ [im_inherited_on_actual, im_on_actual, not_on_surrogate]
      end

      specify 'missing_class_methods returns the class methods on actual but not on surrogate' do
        comparison.missing_class_methods.should =~ [cm_inherited_on_actual, cm_on_actual]
      end

      specify 'instance_type_mismatches returns methods that are on both, but have different type signatures' do
        surrogate = Surrogate.endow(Class.new { def nomatch(a, b=1, *c, d, &e) end
                                                def not_on_actual(a) end })
        actual    =                 Class.new { def nomatch(a, b,   *c, d, &e) end
                                                def not_on_surrogate(a) end }
        described_class.new(surrogate: surrogate, actual: actual)
                       .instance_type_mismatches
                       .map(&:name)
                       .should == [:nomatch]
      end

      specify 'class_type_mismatches returns methods that are on both, but have different type signatures' do
        surrogate = Surrogate.endow(Class.new) { def nomatch(a, b=1, *c, d, &e) end
                                                 def not_on_actual(a) end }
        actual    =                 Class.new  { def self.nomatch(a, b,   *c, d, &e) end
                                                 def self.not_on_surrogate(a) end }
        described_class.new(surrogate: surrogate, actual: actual)
                       .class_type_mismatches
                       .map(&:name)
                       .should == [:nomatch]
      end

      specify 'class_name_mismatches'
      specify 'class_name_mismatches'
    end
  end
end
