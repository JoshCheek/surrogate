require "mockingbird/version"

module Mockingbird
  UnpreparedMethodError = Class.new StandardError

  def self.song_for(klass)
    klass.extend self
    define_initializer_for klass
    klass
  end

  def self.define_initializer_for(klass)
    klass.send :define_method, :initialize do |*args|
      Mockingbird.each_initialization_default_for klass do |ivar_name, value|
        instance_variable_set ivar_name, value
      end
    end
  end

  def self.each_initialization_default_for(klass, &block)
    defaults = klass.instance_variable_get(:@__mockingbird_initializers) || Hash.new
    defaults.each &block
  end

  def self.add_instance_method_to(klass, meth, options)
    klass.send :define_method, meth do
      instance_variable_get "@#{meth}" or 
        options.fetch(:default) {
          raise UnpreparedMethodError, "#{meth} hasn't been invoked without being told how to behave"
        }
    end
  end

  def self.add_default_on_initialization(klass, ivar_name, value)
    klass.instance_eval do
      @__mockingbird_initializers ||= {}
      @__mockingbird_initializers.merge!  "@#{ivar_name}" => value
    end
  end
end



module Mockingbird
  def sing(meth, options={})
    Mockingbird.add_default_on_initialization self, meth, options[:default!] if options.has_key? :default!
    Mockingbird.add_instance_method_to self, meth, options
  end
end
