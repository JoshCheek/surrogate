class Surrogate
  module RSpec
    class TimesPredicate
      attr_accessor :expected_times_invoked, :comparer
      def initialize(expected_times_invoked=0, comparer=:<)
        self.expected_times_invoked = expected_times_invoked
        self.comparer = comparer
      end

      def matches?(invocations)
        expected_times_invoked.send comparer, invocations.size
      end

      def default?
        expected_times_invoked == 0 && comparer == :<
      end
    end
  end
end
