require 'bindable_block'

class Surrogate
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

    def to_hash
      options
    end

    def default(instance, args, block, &no_default)
      if options.has_key? :default
        options[:default]
      elsif default_proc
        # This works for now, but it's a kind of crappy solution because
        # BindableBlock adds and removes methods for each time it is invoked.
        #
        # A better solution would be to instantiate it before passing it to
        # the options, then we only have to bind it to an instance and invoke
        BindableBlock.new(instance.class, &default_proc)
                     .bind(instance)
                     .call(*args, &block)
      else
        no_default.call
      end
    end
  end
end

