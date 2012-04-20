class Surrogate
  module RSpec
    module MessagesFor
      ::RSpec::Matchers.define :be_substitutable_for do |original_class|

        def has_same_instance_methods?(original_class, mocked_class)
          @api_methods = mocked_class.api_method_names
          if @api_methods.empty?
            inherited_methods = mocked_class.instance_methods - mocked_class.instance_methods(false)
            inherited_methods.sort == (original_class.instance_methods - [:new]).sort
          else
            @methods_on_original_class = (original_class.instance_methods & @api_methods)
            @methods_on_original_class.sort == @api_methods.sort
          end
        end

        def has_same_class_methods?(original_class, mocked_class)
          has_same_instance_methods?(original_class.singleton_class, mocked_class.singleton_class)
        end

        match do |mocked_class|
          has_same_instance_methods?(original_class, mocked_class) &&
            has_same_class_methods?(original_class, mocked_class)
        end

        failure_message_for_should do
          "expected #{@api_methods}, got #{@methods_on_original_class}"
        end

        failure_message_for_should_not do
          "expected #{@api_methods} to not equal #{@methods_on_original_class}"
        end
      end
    end
  end
end

