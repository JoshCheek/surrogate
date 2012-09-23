class Surrogate

  # Give it a name and lambda, it will raise an argument error if they don't match, without actually invoking the method.
  # Its error message includes the signature of the message (maybe should also show what was passed in?)
  class ArgumentErrorizer
    attr_accessor :name, :empty_lambda

    def initialize(name, lambda_or_method)
      self.name, self.empty_lambda = name.to_s, lambda_with_same_params_as(lambda_or_method)
    end

    def match!(*args)
      empty_lambda.call *args
    rescue ArgumentError => e
      raise ArgumentError, e.message + " in #{name}(#{lambda_signature empty_lambda})"
    end

    private

    def lambda_with_same_params_as(lambda_or_method)
      eval "->(" << lambda_signature(lambda_or_method) << ") {}"
    end

    def lambda_signature(lambda_or_method)
      lambda_or_method.parameters.map { |type, name| param_for type, name }.compact.join(', ')
    end

    def param_for(type, name)
      case type
      when :req
        name
      when :opt
        "#{name}='?'"
      when :rest
        "*#{name}"
      when :block
        "&#{name}"
      else
        raise "forgot to account for #{type.inspect}"
      end
    end
  end
end
