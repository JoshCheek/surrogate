class Surrogate
  module RSpec
    module MessagesFor
      ::RSpec::Matchers.define :substitute_for do |original_class|

        comparison = nil

        match do |mocked_class|
          comparison = ApiComparer.new(mocked_class, original_class).compare
          (comparison[:instance].values + comparison[:class].values).inject(:+).empty?
        end

        failure_message_for_should do
          extra_instance_methods   = comparison[:instance][:not_on_actual   ].to_a
          extra_class_methods      = comparison[:class   ][:not_on_actual   ].to_a
          missing_instance_methods = comparison[:instance][:not_on_surrogate].to_a
          missing_class_methods    = comparison[:class   ][:not_on_surrogate].to_a

          differences = []
          differences << "has extra instance methods: #{extra_instance_methods.inspect}" if extra_instance_methods.any?
          differences << "has extra class methods: #{extra_class_methods.inspect}"       if extra_class_methods.any?
          differences << "is missing instance methods: #{missing_instance_methods}"      if missing_instance_methods.any?
          differences << "is missing class methods: #{missing_class_methods}"            if missing_class_methods.any?
          "Was not substitutable because " << differences.join(', ')
        end

        failure_message_for_should_not do
          "Should not have been substitute, but was"
        end
      end
    end
  end
end

