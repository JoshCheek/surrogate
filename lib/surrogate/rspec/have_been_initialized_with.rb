class Surrogate
  module RSpec
    class HaveBeenInitializedWith
      LANGUAGE_TYPE = :verb

      include CommonMatcher

      def initialize(*initialization_args, &block)
        super :initialize
        handler.with *initialization_args, &block
      end
    end
  end
end
