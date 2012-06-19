class Surrogate
  class Invocation
    attr_accessor :args, :block

    def initialize(args, &block)
      self.args, self.block = args, block
    end

    def has_block?
      !!block
    end

    def ==(invocation)
      args == invocation.args && has_block? == invocation.has_block?
    end
  end
end
