require 'spec_helper'
require 'surrogate/api_comparer2'


class Surrogate
  describe ApiComparer2 do
    describe 'the methods it finds' do
      %w[ m_with_params
          cm_inherited_on_actual
          im_inherited_on_actual
          cm_inherited_on_surrogate
          im_inherited_on_surrogate
          cmapi_on_surrogate
          imapi_on_surrogate
          cm_on_surrogate
          im_on_surrogate
          cm_on_actual
          im_on_actual
          cmapi
          imapi
          not_on_surrogate
          not_on_actual
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
        end
      end

      def comparison
        @comparison ||= described_class.new(surrogate: surrogate, actual: actual)
      end

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

      # do this if Ruby 2.0
      # it 'uses :req, :opt, :rest, :block, :key, and :keyrest'
    end

    describe 'the :subset option' do
      specify 'when true, ignores methods on actual that are not on surrogate'
    end

    describe 'the :type option' do
      specify 'when false, ignores methods whose parameter types do not match'
    end

    describe 'the :names option' do
      specify 'when false, ignores methods whose parameter names do not match'
    end

    # #compare
    #   tells me about instance methods on actual that are not on surrogate
    #   tells me about class methods on actual that are not on surrogate
    #   tells me about api instance methods on surrogate that are not on actual
    #   tells me about api class methods on surrogate that are not on actual
    #   it tells me the difference when types don't match. Examples:
    #     nothing when arguments are the same
    #     ignores methods that are not on both the surrogate and the actual
    #     ignores methods with no default block
    #     tells me about class methods with different types
    #     tells me about class methods with different types
  end
end
