class Surrogate
  module RSpec
    class HaveBeenInitializedWith
      LANGUAGE_TYPE = :verb

      def initialize(*initialization_args, &block)
        @handler = Handler.new :initialize, self.class::LANGUAGE_TYPE
        handler.with *initialization_args, &block
      end

      attr_reader :handler

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
