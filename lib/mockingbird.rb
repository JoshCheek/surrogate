require 'mockingbird/version'
require 'mockingbird/bird'
require 'mockingbird/egg'
require 'mockingbird/options'
require 'mockingbird/song_queue'
require 'mockingbird/nest_builder'

class Mockingbird
  UnpreparedMethodError = Class.new StandardError

  def self.for(klass, &playlist)
    NestBuilder.build klass, &playlist
    klass
  end
end
