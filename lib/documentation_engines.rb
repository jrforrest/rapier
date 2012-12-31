module Rapier
  # Documentation engines use the API configuration to generate docs for
  # machine, or user education on the API.  Classes in this module should
  # respond to #initialize, taking the API execution context as the sole
  # argument, and should respond to #dox with no arguments, returning the
  # documentation in its final string form.
  module DocumentationEngines
    class JSON
      def initialize(app)
        @app = app
      end

      # Describes an object conf
      def object(conf); {
        :fields => conf.fields.map do |name, conf|; {
          :name => name,
          :descripton => conf.description,
          :required => conf.required,
          :type => conf.type
        }; end,
        # Just reference names of objects
        :objects => conf.objects.map do |name, conf|; {
          :name => name,
          :object_type => conf[:object_type]
        }; end
      }; end

      def dox; {
        :objects => @app.config.response_objects.map do |name, conf|; {
          :name => name,
          :descripton => conf.description
        }.merge(object(conf)); end,
        :routes => @app.config.routes.map do |path, conf|; {
          :path => path,
          :description => conf.description,
          :response_object => object(conf.response_obj),
          :parameters => conf.parameters.map do |name, conf|; {
            :name => name,
            :type => conf.type,
            :required => conf.required
          }; end
        }; end
      }.to_json; end
    end

    class MarkDown
      def initialize(app)
      end
      
      def dox
      end
    end
  end
end
