require 'erb'
require 'surrogate/rspec/have_been_asked_for_its'
require 'surrogate/rspec/have_been_initialized_with'
require 'surrogate/rspec/have_been_told_to'

class Surrogate
  module RSpec
    module Matchers
      def have_been_told_to(expected)
        HaveBeenToldTo.new expected
      end

      def have_been_asked_for_its(expected)
        HaveBeenAskedForIts.new expected
      end

      def have_been_initialized_with(*initialization_args, &block)
        HaveBeenInitializedWith.new *initialization_args, &block
      end
    end
  end
end
