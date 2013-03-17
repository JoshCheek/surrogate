require 'surrogate/helpers'

class Surrogate
  # Give it a name and lambda, it will raise an argument error if they don't match, without actually invoking the method.
  # Its error message includes the signature of the message (maybe should also show what was passed in?)
  class ArgumentErrorizer
    attr_accessor :name, :empty_lambda

    def initialize(name, lambda_or_method)
      Helpers.must_be_lambda_or_method lambda_or_method
      self.name, self.empty_lambda = name.to_s, Helpers.lambda_with_same_params_as(lambda_or_method)
    end

    def match!(*args)
      empty_lambda.call *args
    rescue ArgumentError => e
      raise ArgumentError, e.message + " in #{MethodSignature.new name, empty_lambda.parameters}"
    end
  end
end
