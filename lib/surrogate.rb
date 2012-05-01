require 'surrogate/version'
require 'surrogate/hatchling'
require 'surrogate/hatchery'
require 'surrogate/options'
require 'surrogate/method_queue'
require 'surrogate/endower'
require 'surrogate/api_comparer'

class Surrogate
  UnpreparedMethodError = Class.new StandardError

  def self.endow(klass, &block)
    Endower.endow klass, &block
    klass
  end
end
