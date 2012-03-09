class Mockingbird
  class SongQueue < Struct.new(:queue)
    QueueEmpty = Class.new StandardError

    def dequeue
      raise QueueEmpty if empty?
      queue.shift
    end

    def empty?
      queue.empty?
    end
  end
end
