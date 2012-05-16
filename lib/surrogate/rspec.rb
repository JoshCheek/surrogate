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
  end
end

require 'surrogate'
require 'surrogate/rspec/api_method_matchers'
require 'surrogate/rspec/substitutability_matchers'
