class Surrogate
  module RSpec
    class HaveBeenToldTo
      LANGUAGE_TYPE = :verb

      include CommonMatcher

      def times(number)
        handler.times number
        self
      end

      def with(*arguments, &block)
        handler.with *arguments, &block
        self
      end
    end
  end
end
