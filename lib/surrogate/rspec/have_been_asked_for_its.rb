class Surrogate
  module RSpec
    class HaveBeenAskedForIts
      LANGUAGE_TYPE = :noun

      def times(number)
        handler.times number
        self
      end

      def with(*arguments, &block)
        handler.with *arguments, &block
        self
      end

      attr_reader :handler

      def initialize(expected)
        @handler = Handler.new expected, self.class::LANGUAGE_TYPE
      end

      def matches?(mocked_instance)
        handler.instance = mocked_instance
        handler.match?
      end

      def failure_message_for_should_not
        handler.failure_message_for_should_not
      end

      def failure_message_for_should
        handler.failure_message_for_should
      end
    end
  end
end
