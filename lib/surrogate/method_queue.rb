class Surrogate
  class MethodQueue < Struct.new(:queue)
    QueueEmpty = Class.new StandardError

    def dequeue
      raise QueueEmpty if empty?
      current = queue.shift
      raise current if current.kind_of? Exception
      current
    end

    def empty?
      queue.empty?
    end
  end
end
