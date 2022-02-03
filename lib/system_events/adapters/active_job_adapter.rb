module SystemEvents
  module Adapters
    class ActiveJobAdapter

      def initialize(listeners_path:,
                     parent_class: ActiveJob::Base,
                     default_queue: :default)
        @listeners_path = listeners_path
        @parent_class = parent_class
        @default_queue = default_queue

        setup_adapter_job_class!
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

      attr_reader :listeners_path, :parent_class, :default_queue

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

      def setup_adapter_job_class!
        klass = Class.new parent_class do

          def perform(klass, event_name, *args, **kwargs)
            klass.new.public_send(event_name, *args, **kwargs)
          end
        end
        klass.queue_as default_queue

        self.class.const_set(:AdapterJob, klass)
      end
    end
  end
end
