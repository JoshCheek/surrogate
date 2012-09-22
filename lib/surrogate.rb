require 'surrogate/version'
require 'surrogate/hatchling'
require 'surrogate/hatchery'
require 'surrogate/method_definition'
require 'surrogate/values'
require 'surrogate/endower'
require 'surrogate/api_comparer'
require 'surrogate/invocation'

class Surrogate
  UnpreparedMethodError = Class.new StandardError

  def self.endow(klass, &block)
    Endower.endow klass, &block
    klass
  end
end
