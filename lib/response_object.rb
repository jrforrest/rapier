module Rapier
  module ConfigurationContext
    # Response Objects serve as a formal specification for JSON objects
    # to be given in response to client requests.  These objects are
    # comprised of fields, which represent strictly typed values, or
    # child objects which must be specified in the API configuration.
    class ResponseObject
      attr_accessor :description
      attr_reader :fields, :objects

      # @yield [response_object] The configuration block for this 
      #   response object
      # @yieldparam [ConfigurationContext::ResponseObject]
      #   This object yields itself to the given configuration block
      def initialize(&block)
        @fields = Hash.new
        @objects = Hash.new
        block.call(self) if block
      end

      # Adds a field to this object's specification
      #
      # @param [Symbol] name The name of this field
      # @param [Hash] opts The options to be for this field.  See
      #   {ConfigurationContext::ResponseField#initialize}
      def field(name, opts)
        unless name.kind_of?(Symbol)
          raise ArgumentError, 'name should be a Symbol!' 
        end
        @fields[name] = ResponseField.new(name, opts)
      end

      # Adds a child object to this object's specification
      #
      # @param [Symbol] name The name of this object.  This will be used
      #   as both the name of the field in the JSON response, and to look
      #   up the object specification given at the API level.
      # @param [Hash] opts The options for
      def object(name, opts)
        @objects[name] = opts 
      end
    end
  end
  
  module ExecutionContext
    # Abandon all hope ye who enter here.
    class ResponseObject
      # Prepares a response object for use in a response handler.  This
      # handles validation of configuration and instantiation of all
      # child fields and objects.
      #
      # @note
      #   I know what you're thinking, this looks awful.  I'm here to
      #   assure you that it's just as bad as it looks.
      #
      # @params [ConfigurationContext::API] api_conf The configuration for the 
      #   API to which this object belongs
      # @params [ConfigurationContext::ResponseObject] ro_conf The 
      #    configuration for this response object
      def initialize(api_conf, ro_conf)
        @api_config, @config = api_conf, ro_conf
        @objects = Hash.new

        # Create an execution context object for all nested objects.  This
        # recurses, of course
        @config.objects.each do |name, object_conf|
          if not @api_config.response_objects[name]
            raise ConfigurationError, "Object #{name} is not defined!"
          end
          @objects[name] = ResponseObject.new(
            @api_config, @api_config.response_objects[name])
        end

        @fields = Hash.new
        # Create an execution context for all fields
        @config.fields.each do |name, field_conf|
          @fields[name] = ResponseField.new(field_conf)
        end

        # Ensure that we haven't used duplicate names
        unless (@fields.keys & @objects.keys).empty?
          raise ConfigurationError, "Field names may not be used "\
            "more than once in an object definition!"
        end

        # Define accessor methods on our singleton class for all of the
        # fields in this object
        @fields.each do |name, value|
          singleton_class = class << self; self; end
          singleton_class.send(:define_method, name) { @fields[name].value }
          singleton_class.
            send(:define_method, "#{name}=") {|v| @fields[name].set(v) }
        end

        # Define reader methods for the child objects
        @objects.each do |name, value|
          (class << self; self; end).
            send(:define_method, name) { @objects[name] }
        end
      end

      # Sets the fields and child objects with the corresponding values in
      # the given +hash+
      #
      # @note
      #   This method recurses for child objects
      #
      # @param [Hash<Symbol => Object>] hash the Hash of values to be set.
      #   Keys in this hash should correspond to the fields or child
      #   objects by name.  Values in the hash should be type-appropriate
      #   for the fields to which they belong.  If the field denoted by
      #   the key is a child object, the value should be either a hash which
      #   contains the value to be set for the child object, or an object
      #   which exposes accessors with names that correspond to the fields
      #   of the child object.
      def set_from_hash(hash)
        hash.each do |key, value|
          if @fields.include?(key)
            @fields[key].set(value)
          elsif @objects.include?(key)
            if value.class == Hash
              @objects[key].set_from_hash(value)
            else
              @objects[key].set_from_attrs(value)
            end
          end
        end
      end

      # Sets the fields and child objects with the corresponding values
      # given by accessors in the given object
      #
      # @param [Object] obj The object from which fields should be set.
      #   Accessors in this object will be used to set the fields in
      #   this response object with a corresponding name.  This method
      #   recurses for fields denoting child objects, so values of accessors
      #   with names that correspond to child objects should be either Hashes
      #   or objects with accessors that correspond to the fields of the child
      #   object.
      # @param [Hash] opts Extra options
      # @option opts [Array<Symbol>] :exclude Fields to exclude from
      #   assignement from the accessor on +obj+ with a corresponding name
      def set_from_attrs(obj, opts = {})
        exclude = opts.delete(:exclude) || Array.new

        @fields.each do |name, field|
          next if exclude.include?(name)
          field.set(obj.send(name)) if obj.respond_to?(name)
        end

        @objects.each do |name, res_obj|
          next if exclude.include?(name)
          next unless obj.respond_to?(name)

          if obj.send(name).class == Hash
            res_obj.set_from_hash(obj.send(name))
          else
            res_obj.set_from_attrs(obj.send(name))
          end
        end
      end

      # Checks for assignement of required fields in this response object,
      # and operates recursively for child objects to ensure that their
      # required fields have been set as well.
      #
      # @note
      #   Type errors should be caught when the field is set.
      #
      # @raises [ResponseError] Denotes a situation where a field or
      #   object is not valid.
      def validate
        @objects.each do |name, obj| 
          begin
            obj.validate
          rescue ResponseError => e
            raise ResponseError, "Object: #{name}: #{e.message}"
          end
        end
          
        # Maybe I should centralize this logic under that GenericField class
        @fields.each do |name, field| 
          if field.required? and not field.value
            raise ResponseError, "Field #{name} should be set!"
          end
        end
      end

      # @return [Hash<Symbol => Object>] A hash containing the values assigned
      #   to the fields of this object.  Child objects will be represented
      #   recursively by Hashes.
      def to_hash
        hash = {}
        @objects.each { |name, obj| hash[name] = obj.to_hash }
        @fields.each { |name, field| hash[name] = field.value }
        return hash
      end
    end
  end
end
