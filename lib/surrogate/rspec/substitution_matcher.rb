class Surrogate
  module RSpec
    class SubstitutionMatcher
      def initialize(original_class, options={})
        @original_class = original_class
        @comparison     = nil
        @subset_only    = options.fetch :subset, false
        @types          = options.fetch :types,  true
        @names          = options.fetch :names,  false
      end

      def matches?(surrogate)
        @comparison = ApiComparer.new(surrogate, @original_class).compare
        comparing_fields(@comparison, @subset_only, @types, @names).values.inject(:+).empty?
      end


      def failure_message_for_should
        extra_instance_methods   = @comparison[:instance][:not_on_actual   ].to_a # these come in as sets
        extra_class_methods      = @comparison[:class   ][:not_on_actual   ].to_a
        missing_instance_methods = @comparison[:instance][:not_on_surrogate].to_a
        missing_class_methods    = @comparison[:class   ][:not_on_surrogate].to_a
        instance_type_mismatch   = @comparison[:instance][:types           ]
        class_type_mismatch      = @comparison[:class   ][:types           ]
        instance_name_mismatch   = @comparison[:instance][:names           ]
        class_name_mismatch      = @comparison[:class   ][:names           ]


        differences = []
        differences << "has extra instance methods: #{extra_instance_methods.inspect}" if extra_instance_methods.any?
        differences << "has extra class methods: #{extra_class_methods.inspect}"       if extra_class_methods.any?
        differences << "is missing instance methods: #{missing_instance_methods}"      if !@subset_only && missing_instance_methods.any?
        differences << "is missing class methods: #{missing_class_methods}"            if !@subset_only && missing_class_methods.any?

        if @types # this conditional is not tested, nor are these error messages
          instance_type_mismatch.each { |name, types| differences << "##{name} had types #{types.inspect}" }
          class_type_mismatch.each    { |name, types| differences << ".#{name} had types #{types.inspect}" }
        end

        if @names # this conditional is not tested, nor are these error messages
          instance_name_mismatch.each { |method_name, param_names| differences << "##{method_name} had parameter names #{param_names.inspect}" }
          class_type_mismatch.each    { |method_name, param_names| differences << ".#{method_name} had parameter names #{param_names.inspect}" }
        end
        "Was not substitutable because surrogate " << differences.join("\n")
      end

      def failure_message_for_should_not
        "Should not have been substitute, but was"
      end

    private

      def comparing_fields(comparison, subset_only, types, names)
        fields = {}
        fields[:instance_not_on_actual   ] = comparison[:instance][:not_on_actual]
        fields[:class_not_on_actual      ] = comparison[:class   ][:not_on_actual]
        fields[:instance_not_on_surrogate] = comparison[:instance][:not_on_surrogate] unless @subset_only
        fields[:class_not_on_surrogate   ] = comparison[:class   ][:not_on_surrogate] unless @subset_only
        fields[:instance_types           ] = comparison[:instance][:types]            if @types
        fields[:class_types              ] = comparison[:class   ][:types]            if @types
        fields[:instance_names           ] = comparison[:instance][:names]            if @names
        fields[:class_names              ] = comparison[:class   ][:names]            if @names
        fields
      end
    end
  end
end
