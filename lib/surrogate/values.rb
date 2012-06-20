class Surrogate

  # Superclass for all types of values. Where a value is anything stored
  # in an instance variable on a surrogate, intended to be returned by an api method
  class Value
    # convert raw arguments into a value
    def self.factory(*args, &block)
      arg = args.first
      if args.size > 1
        ValueQueue.new args
      elsif arg.kind_of? Exception
        Raisable.new arg
      elsif arg.kind_of? BaseValue
        arg
      else
        BaseValue.new arg
      end
    end

    # === the current set of possible values ===

    class BaseValue
      def initialize(value)
        @value = value
      end

      def value(hatchling, method_name)
        @value
      end

      def factory(*args, &block)
        Value.factory(*args, &block)
      end
    end


    class Raisable < BaseValue
      def value(*)
        raise @value
      end
    end


    class ValueQueue < BaseValue
      QueueEmpty = Class.new StandardError

      def value(hatchling, method_name)
        factory(dequeue).value(hatchling, method_name)
      ensure
        hatchling.unset_ivar method_name if empty?
      end

      def queue
        @value
      end

      def dequeue
        raise QueueEmpty if empty?
        queue.shift
      end

      def empty?
        queue.empty?
      end
    end
  end
end
