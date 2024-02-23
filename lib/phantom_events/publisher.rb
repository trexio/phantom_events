module PhantomEvents
  module Publisher
    def publish(event_name, *args, **kwargs)
      PhantomEvents.config.adapters.each do |adapter|
        adapter.handle_event(event_name, *args, **kwargs)
      end

      event_name
    end
  end
end
