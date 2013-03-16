# Maybe I should be my own gem?

require 'rspec/core'
require 'rspec/expectations'
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
      def be_substitutable_for(original_class, options={})
        SubstitutionMatcher.new original_class, options
      end

      def substitute_for(original_class, options={})
        SubstitutionMatcher.new original_class, options
      end

      def have_been_told_to(method_name)
        VerbMatcher.new method_name
      end

      def told_to(method_name)
        VerbMatcher.new method_name
      end

      def have_been_asked_if(method_name)
        PredicateMatcher.new method_name
      end

      def asked_if(method_name)
        PredicateMatcher.new method_name
      end

      def have_been_asked_for_its(method_name)
        NounMatcher.new method_name
      end

      def asked_for(method_name)
        NounMatcher.new method_name
      end

      def have_been_initialized_with(*initialization_args, &block)
        InitializationMatcher.new *initialization_args, &block
      end

      def initialized_with(*initialization_args, &block)
        InitializationMatcher.new *initialization_args, &block
      end
    end
  end

  Endower.add_hook do |klass|
    klass.class_eval do
      @hatchery.helper_methods << :was << :was_not
      alias was should
      alias was_not should_not
    end
  end
end

require 'surrogate/rspec/substitution_matcher'
require 'surrogate/rspec/predicate_matcher'
require 'surrogate/rspec/noun_matcher'
require 'surrogate/rspec/initialization_matcher'
require 'surrogate/rspec/verb_matcher'


RSpec.configure do |config|
  config.include Surrogate::RSpec::Matchers
end
