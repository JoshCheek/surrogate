require 'surrogate/rspec/verb_matcher'

class Surrogate
  module RSpec
    class InitializationMatcher < VerbMatcher
      def initialize(*initialization_args, &block)
        super :initialize
        with *initialization_args, &block
      end
    end
  end
end
