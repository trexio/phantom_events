module SystemEvents
  module Adapters
    class ActiveJobAdapter

      class AdapterJob < ActiveJob::Base # inject custom parent class
        queue_as :default # make this configurable

        def perform(klass, event_name, *args, **kwargs)
          klass.new.public_send(event_name, *args, **kwargs)
        end
      end

      def initialize(listeners_path:)
        @listeners_path = listeners_path
      end

      def handle_event(event_name, *args, **kwargs)
        listeners_for_event(event_name).each do |listener_klass|
          AdapterJob.perform_later(listener_klass, event_name, *args, **kwargs)
        end
      end

      def handles_event?(event_name)
        listeners_for_event(event_name).any?
      end

      private

      attr_reader :listeners_path

      def listeners
        listeners_path.glob("**/*.rb").map do |pathname|
          relative = pathname.relative_path_from(listeners_path).sub_ext("")
          relative.to_s.classify.safe_constantize
        end
      end

      def listeners_for_event(event_name)
        listeners.select do |listener|
          listener.instance_methods.include?(event_name)
        end
      end
    end
  end
end
