module SystemEvents
  class Configuration

    attr_reader :adapters

    def initialize(&_block)
      @adapters = []
      yield self
    end

    def register_adapter(name, **kwargs)
      require "system_events/adapters/#{name}_adapter"
      klass = "SystemEvents::Adapters::#{name.to_s.camelize}Adapter".safe_constantize
      @adapters << klass.new(**kwargs)
    end
  end
end
