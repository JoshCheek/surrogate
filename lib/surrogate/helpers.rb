class Surrogate
  module Helpers
    extend self

    # Eventually make this return a real lambdba, not a method
    # I'm just feeling really lazy right now, and want to get this working
    # before I do the refactorings
    def block_to_lambda(block)
      o = Object.new
      o.define_singleton_method :temp_method, &block
      o.method :temp_method
    end

    def lambda_with_same_params_as(proc)
      eval "->(" << signature_types_and_names(proc.parameters) << ") {}"
    end

    def method_signature(name, parameters)
      "#{name}(#{signature_types_and_names parameters})"
    end

    def signature_types_and_names(parameters)
      parameters.map { |type, name| param_for type, name }.compact.join(', ')
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
        # here we need Ruby 2.0 specific stuff
        raise "forgot to account for #{type.inspect}"
      end
    end

    def must_be_lambda_or_method(lambda_or_method)
      return if lambda_or_method.kind_of? ::Method
      return if lambda_or_method.kind_of?(Proc) && lambda_or_method.lambda?
      raise ArgumentError, "Expected a lambda or method, got a #{lambda_or_method.class}"
    end
  end
end
