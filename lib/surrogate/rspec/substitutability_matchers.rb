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
          "Should have been substitute, but found these differences #{comparison.inspect}"
        end

        failure_message_for_should_not do
          "Should not have been substitute, but was"
        end
      end
    end
  end
end

