class Surrogate
  module RSpec
    module CommonMatcher
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
