class Mockingbird
  class Options
    attr_accessor :options, :default_proc

    def initialize(options, default_proc)
      self.options, self.default_proc = options, default_proc
    end

    def has?(name)
      options.has_key? name
    end

    def [](key)
      options[key]
    end

    def default(instance, args, &no_default)
      return options[:default] if options.has_key? :default
      return instance.instance_exec(*args, &default_proc) if default_proc
      no_default.call
    end
  end
end

