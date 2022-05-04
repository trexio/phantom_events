module PhantomEvents
  class Configuration

    attr_reader :adapters

    def initialize(&_block)
      @adapters = []
      @listeners = []
      yield self
    end

    def register_adapter(name, **kwargs)
      require "phantom_events/adapters/#{name}_adapter"
      klass = "PhantomEvents::Adapters::#{name.to_s.camelize}Adapter".safe_constantize
      @adapters << klass.new(**kwargs)
    end

    def register_listener(klass)
      @listeners << klass
    end
  end
end
