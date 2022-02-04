module SystemEvents
  module Publisher
    def publish(event_name, *args, **kwargs)
      adapters_for(event_name).each do |adapter|
        adapter.handle_event(event_name, *args, **kwargs)
      end

      event_name
    end

    private

    def adapters_for(event_name)
      SystemEvents.config.adapters.select do |adapter|
        adapter.handles_event?(event_name)
      end
    end
  end
end
