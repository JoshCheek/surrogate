# Maybe I should be my own gem?

class Surrogate
  module RSpec
    class << self
      def rspec_mocks_loaded?
        return @mocks_loaded if @alrady_checked_mocks
        @alrady_checked_mocks = true
        require 'rspec/mocks' # can't figure out a way to do this lazily
        @mocks_loaded = true
      rescue LoadError
        @mocks_loaded = false
      end

      def rspec_mocks_loaded=(bool)
        @alrady_checked_mocks = true
        @mocks_loaded = bool
      end
    end

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

require 'rspec/core'
require 'surrogate'
require 'surrogate/rspec/substitutability_matchers'

require 'surrogate/rspec/have_been_asked_for_its'
require 'surrogate/rspec/have_been_initialized_with'
require 'surrogate/rspec/have_been_told_to'


RSpec.configure do |config|
  config.include Surrogate::RSpec::Matchers
end
