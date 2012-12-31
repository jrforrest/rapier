module Rapier
  module ConfigurationContext
    class API
      # @return [Hash<String => ConfigurationContext::Route>]
      #   The routes belonging to this API
      attr_reader :routes
      # @return [Hash<Symbol => ConfigurationContext::ResponseObject>]
      #   The object specs belonging to this API
      attr_reader :response_objects
      # @return [Boolean] Should this API return the JSON spec for this API
      #   for requests to /api_spec.json?
      attr_accessor :enable_spec

      def initialize
        @routes = Hash.new
        @response_objects = Hash.new
      end

      # Adds a route to the api.  Requests to +path+ will be handled by this
      # route.
      # @param [String] path Requests to +path+ will be handled by this route 
      # @param [block] 
      # @yield [route_config] Configures the newly created route
      # @yieldparam [ConfigurationContext::Route] The configuration object 
      #   for the newly created route
      def route(path, &block)
        raise ArgumentError, 'Block expected!' unless block
        @routes[path] = Route.new(path)
        block.call(@routes[path])
      end

      # Adds an object specification to the API.
      #
      # @param [Symbol] name The name of the object spec
      # @yield [object_spec] Configures the newly created object spec
      # @yieldparam [ConfigurationContext::ResponseObject] The configuration
      #   object for the newly created object spec
      def object(name, &block) 
        unless name.kind_of?(Symbol)
          raise ::TypeError, "name should be a Symbol"
        end
        @response_objects[name] = ResponseObject.new(&block)
      end
    end
  end

  module ExecutionContext
    class API
      attr_reader :config

      def initialize
        raise ArgumentError, 'Block expected!' unless block_given?
        @config = ConfigurationContext::API.new
        yield(@config)

        validate_configuration
      end

      # This is the entry point in a Rack context.
      #
      # @param [Array] env The Rack environment
      def call(env)
        request = Rack::Request.new(env)

        if request.path_info == '/api_spec.json' and @config.enable_spec
          response = Rack::Response.new
          response.headers['Content-Type'] = 'application/json'
          response.write DocumentationEngines::JSON.new(self).dox
          return response.finish
        end
        
        unless @config.routes[request.path_info]
          response = Rack::Response.new
          response.headers['Content-Type'] = 'application/json'
          response.status = 404
          response.write({:message => 'Route not found!'}.to_json)
          return response.finish
        end

        route = ExecutionContext::Route.new(
          @config, @config.routes[request.path_info])
        route.execute(request).finish
      end

      protected

      # Instantiates execution contexts for routes and objects belonging to
      # this API, ensuring that their configurations are correct
      #
      # @todo
      #   Some of this validation should be ensured when the objects are
      #   configured, to provide meaningful stack traces to the user
      def validate_configuration
        @config.routes.each do |key, route_conf|
          ExecutionContext::Route.new(@config, route_conf)
        end
      end
    end
  end

  API = ExecutionContext::API
end
