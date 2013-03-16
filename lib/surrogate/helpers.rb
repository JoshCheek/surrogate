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
  end
end
