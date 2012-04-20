class Surrogate
  module RSpec
    module MessagesFor
      ::RSpec::Matchers.define :be_substitutable_for do |original_class|

        match do |mocked_class|
          comparison = ApiComparer.new(mocked_class, original_class).compare
          (comparison[:instance].values + comparison[:class].values).inject(:+).empty?
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

