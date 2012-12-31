module Rapier
  module ConfigurationContext
    # Request Parameters represent the POST and GET parameters sent
    # in the HTTP request.  These parameters are type-checked previous
    # to execution of a Route's response block.
    class RequestParameter
      # @return [String] The description for this parameter
      attr_accessor :description
      # @return [Symbol] The type for this parameter
      attr_accessor :type
      # @return [true,false] Is this parameter required?
      attr_accessor :required
      # @return [String] The name of this parameter
      attr_reader :name

      # @param [String] name The name of this parameter.  This will also serve
      #   as the HTTP parameter name as well.
      # @param [Hash] opts The configuration options for this parameter
      # @option opts [String] :description The description of this parameter
      # @option opts [Symbol] :type The type of this parameter.  One of
      #   :string, :float, :integer or :boolean
      # @option opts [true, false] :required Is this parameter required?  The
      #   response will carry a 400 status if a required parameter is not
      #   given.
      def initialize(name, opts = {})
        @name = name 
        @description = opts.delete(:description)
        @type = opts.delete(:type)
        @required = opts.delete(:required)

        if not (@name and @type)
          raise ArgumentError, "name and type are required for parameters!"
        end
      end
    end
  end

  module ExecutionContext
    class RequestParameter < GenericField; end
  end
end
