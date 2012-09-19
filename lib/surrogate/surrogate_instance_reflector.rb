class Surrogate

  # Utilities for reflecting on surrogate instances
  #
  # Primarily it exists to avoid having to pollute the surrogate with reflection methods
  class SurrogateInstanceReflector < Struct.new(:surrogate)
    def invocations(method_name)
      hatchling.invocations(method_name)
    end

    def hatchling
      @hatchling ||= surrogate.instance_variable_get :@hatchling
    end
  end
end
