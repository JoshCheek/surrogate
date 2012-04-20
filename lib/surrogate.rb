require 'surrogate/version'
require 'surrogate/hatchling'
require 'surrogate/hatchery'
require 'surrogate/options'
require 'surrogate/method_queue'
require 'surrogate/endower'
require 'surrogate/api_comparer'

class Surrogate
  UnpreparedMethodError = Class.new StandardError

  # TODO: Find a new name that isn't "playlist"
  def self.endow(klass, &playlist)
    Endower.endow klass, &playlist
    klass
  end
end
