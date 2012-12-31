module Rapier
  module ConfigurationContext
    # Response Fields represent fields in the JSON objects returned by
    # this API.  These are strictly typed.
    class ResponseField
      attr_accessor :type, :description, :required, :name
      TYPES = [:string, :integer, :float, :boolean]

      # @parameter [Symbol] name The name of this field
      # @parameter [Hash] opts Configuration options for this field
      # @option opts [Symbol] :type The type of this field
      # @option opts [String] :description The descriptoin of this field
      # @option opts [Boolean] :required Is this field required?
      def initialize(name, opts = Hash.new)
        @name = name
        @type = opts.delete(:type)
        @descripton = opts.delete(:description)
        @required = opts.delete(:required)

        unless (@name and @type)
          raise ConfigurationError, "name and type are required for parameters!"
        end

        unless TYPES.include?(@type)
          raise ConfigurationError, "#{@type} is not a valid type! "\
            "(Must be one of #{TYPES})"
        end
      end
    end
  end

  module ExecutionContext
    # These two behave the same, kind of by accident.  Used a generic parent
    # class for now, but keep an eye on out for further refactoring 
    # opportunities later on
    class ResponseField < GenericField
      # Sets this field to the given +value+
      #
      # @param [Object] value The value that this field should be set to.  Must
      #   be of the same type as this field.
      # @raises [TypeError] The given +value+ does not match the type of
      #   this field
      def set(value) 
        valid = case @configuration.type
          when :string then value.kind_of?(String)
          when :integer then value.kind_of?(Fixnum)
          when :float then value.kind_of?(Float)
          when :boolean then [true, false].include?(value)
          else false
        end

        unless valid
          raise TypeError, 
            "#{@configuration.name} is not a #{@configuration.type}"
        end

        @value = value
      end
    end
  end
end
