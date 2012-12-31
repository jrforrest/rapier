require 'json'
require 'api'
require 'response_object'
require 'documentation_engines'
require 'generic_field'
require 'request_parameter'
require 'route'
require 'response_field'

# Rapier is a library for building Rack applications which provide a strict
# interface for JSON based APIs
module Rapier
  # Denotes a situation where an unnaceptable type has been given
  class TypeError < StandardError; end
  # Denotes a situation where an object was not properly configured
  class ConfigurationError < StandardError; end
  # Denotes a situation where a response was not properly specified
  class ResponseError < StandardError; end

  # The configuration and execution context modules are used to differentate
  # between objects that are yielded to the user in configuration blocks, and
  # the implementations of those objects that do the actual work.
  module ConfigurationContext; end

  # The configuration and execution context modules are used to differentate
  # between objects that are yielded to the user in configuration blocks, and
  # the implementations of those objects that do the actual work.
  module ExecutionContext; end
end
