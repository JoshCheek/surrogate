# Maybe I should be my own gem?

require 'rspec/core'
require 'surrogate'

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
      def have_been_told_to(method_name)
        HaveBeenToldTo.new method_name
      end

      def told_to(method_name)
        HaveBeenToldTo.new method_name
      end

      def have_been_asked_if(method_name)
        HaveBeenAskedIf.new method_name
      end

      def asked_if(method_name)
        HaveBeenAskedIf.new method_name
      end

      def have_been_asked_for_its(method_name)
        HaveBeenAskedForIts.new method_name
      end

      def asked_for(method_name)
        HaveBeenAskedForIts.new method_name
      end

      def have_been_initialized_with(*initialization_args, &block)
        HaveBeenInitializedWith.new *initialization_args, &block
      end

      def initialized_with(*initialization_args, &block)
        HaveBeenInitializedWith.new *initialization_args, &block
      end
    end
  end

  Endower.add_hook do |klass|
    klass.class_eval do
      alias was should
      alias was_not should_not
    end
  end
end

require 'surrogate/rspec/substitute_for'
require 'surrogate/rspec/have_been_asked_if'
require 'surrogate/rspec/have_been_asked_for_its'
require 'surrogate/rspec/have_been_initialized_with'
require 'surrogate/rspec/have_been_told_to'


RSpec.configure do |config|
  config.include Surrogate::RSpec::Matchers
end
