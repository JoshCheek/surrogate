require 'surrogate/rspec/have_been_told_to'

class Surrogate
  module RSpec
    class HaveBeenInitializedWith < HaveBeenToldTo
      def initialize(*initialization_args, &block)
        super :initialize
        with *initialization_args, &block
      end
    end
  end
end
