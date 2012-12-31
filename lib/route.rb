module Rapier
  module ConfigurationContext
    # Routes house the handling logic for requests for the path
    # to which they are assigned.
    class Route
      # @return [Hash<Symbol => RequestParameter>]
      #   The request parameters that this route takes
      attr_reader :parameters

      # @return [ConfigurationContext::ResponseObject]
      #   The response object for this route specifies the JSON
      #   object that it returns.
      attr_reader :response_obj

      # @return [Proc] The block that will be called to handle incoming
      #   requests.  This is set with +#respond+
      attr_reader :response_block

      # @return [String] The description string for this route.  This is
      #   used primarily for documentation generation
      attr_accessor :description

      # @param [ConfigurationContext::API] api_configuration
      #   The configuration for the API to which this route belongs
      def initialize(api_configuration)
        @api_configuration = api_configuration
        @parameters = Hash.new
        @response_obj = ResponseObject.new
      end

      # Adds a request parameter for this route
      # 
      # @param [String] name The name of the request parameter
      # @param [Hash] opts Options for the new request parameter.  See
      #   {Rapier::ConfigurationContext::RequestParameter#initialize} for
      #   these options.
      def parameter(name, opts = Hash.new)
        @parameters[name.to_s] = RequestParameter.new(name, opts)
      end

      # Sets the response block for this route
      #
      # @note
      #   Currently there is no way to access headers, cookies or any
      #   other sort of HTTP nonsesense in the response block.  Functionality
      #   having to do with these details should be handled by proxies or
      #   Rack middleware.
      #
      # @yield This block will be given the validated request parameters,
      #   and the response object for this request, and must set all
      #   required fields in the response object.
      # @yieldparam [Hash<Symbol => Object]
      #   A dictionary of the validated request parameter values given in the
      #   request.
      # @yieldparam [Hash<Symbol => ExecutionContext::ResponseObject>]
      #   The response object for this route.  All sub-objects and fields will
      #   already be initialized.  Required fields on this object and it's
      #   children must be specified by the response block.
      def respond(&block)
        @response_block = block
      end

      # Sets the response object for this route
      #
      # @see ConfigurationContext::ResponseObject
      #
      # @yield The configuration block for the response object specification
      # @yieldparam [ConfigurationContext::ResponseObject]
      #   The configuration for the response object for this block.
      def response_object(&block)
        raise ArgumentError, 'Block expected!' unless block
        block.call(@response_obj)
      end
    end
  end

  module ExecutionContext
    class Route
      # Creates the execution context for a route, with the given
      # api level, and route level configurations
      #
      # @param [ConfigurationContext::API] The configuration for the API that
      #   this handler belongs to
      # @param [ConfigurationContext::Route] The configuration for this handler
      def initialize(api_conf, route_conf)
        @api_conf, @route_conf = api_conf, route_conf
        unless @route_conf.response_block
          raise ScriptError, "Response not specified!"
        end
        @params = Hash.new
        @response_obj = ResponseObject.new(@api_conf, @route_conf.response_obj)
      end

      # Executes the given block, rescuing exceptions that occur with
      # the exception handlers set up for this Route
      def with_exceptions_handled
        raise ArgumentError, 'Block expected!' unless block_given?
        begin
          yield
        rescue StandardError => e
          ex_handlers = @api_conf.ex_handlers.merge(@route_conf.ex_handlers)
          superclass = e.class
          while(superclass != Object)
            handler = ex_handlers[superclass]
            superclass = superclass.superclass
          end
        end
      end

      # Fufills the given request and returns a response
      # 
      # @param [Rack::Request] request The request to be processed
      # @return [Rack::Response] The response to the given request,
      #   formed according to this object's configuration
      def execute(request)
        response = Rack::Response.new
        response.headers['Content-Type'] = 'application/json'

        begin
          assign_params(request.params)
        rescue TypeError => e
          response.status = 400
          response.write({:message => e.message}.to_json)
          return response
        end

        @route_conf.response_block.call(
          @params.reduce({}) {|h, (k,v)| h[k] = v.value; h},
          @response_obj)

        @response_obj.validate

        response.write(@response_obj.to_hash.to_json)
        return response
      end

      protected

      def assign_params(params)
        params.each do |key, value|
          next unless @route_conf.parameters.include?(key)

          @params[key] = RequestParameter.new(@route_conf.parameters[key])
          @params[key].set(value)
        end

        # Ensure all requied parameters are given
        @route_conf.parameters.each do |name, param_conf|
          if not @params.include?(name) and param_conf.required
            raise TypeError, "Parameter: #{name} is required!"
          end
        end
      end
    end
  end
end
