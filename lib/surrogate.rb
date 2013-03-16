require 'surrogate/version'
require 'surrogate/hatchling'
require 'surrogate/hatchery'
require 'surrogate/method_definition'
require 'surrogate/values'
require 'surrogate/endower'
require 'surrogate/invocation'
require 'surrogate/errors'
require 'surrogate/api_comparer'
require 'surrogate/surrogate_class_reflector'
require 'surrogate/surrogate_instance_reflector'

class Surrogate
  def self.endow(klass, options={},  &block)
    Endower.endow klass, options, &block
    klass
  end
end
