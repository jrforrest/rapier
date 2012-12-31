module Rapier
  class GenericField
    attr_reader :value

    def initialize(config)
      @configuration = config
      @value = nil
    end

    def required?
      @configuration.required
    end

    def set(value) 
      @value = case @configuration.type
      when :string then value.to_s
      when :integer then Integer(value)
      when :float then Float(value)
      when :boolean then
        raise ArgumentError unless ['true', 'false'].include?(value)
        value == 'true' ? 'true' : 'false'
      end

    rescue ArgumentError => e
      raise TypeError, 
        "#{@configuration.name} is not a #{@configuration.type}"
    end
  end
end
