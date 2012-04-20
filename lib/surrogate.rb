require 'surrogate/version'
require 'surrogate/bird'
require 'surrogate/egg'
require 'surrogate/options'
require 'surrogate/method_queue'
require 'surrogate/nest_builder'

class Surrogate
  UnpreparedMethodError = Class.new StandardError

  def self.for(klass, &playlist)
    NestBuilder.build klass, &playlist
    klass
  end
end
