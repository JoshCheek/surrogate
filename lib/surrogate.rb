require 'surrogate/version'
require 'surrogate/bird'
require 'surrogate/egg'
require 'surrogate/options'
require 'surrogate/method_queue'
require 'surrogate/endower'

class Surrogate
  UnpreparedMethodError = Class.new StandardError

  def self.endow(klass, &playlist)
    Endower.endow klass, &playlist
    klass
  end
end
