require 'surrogate/helpers'

class Surrogate
  class MethodSignature
    attr_accessor :name, :params
    def initialize(name, params)
      self.name, self.params = name, params
    end

    def param_names
      params.map(&:last)
    end

    def param_types
      params.map(&:first)
    end

    def reflectable?
      params.all? { |type, name| type && name }
    end

    def to_s
      Helpers.method_signature name, params
    end
  end
end
