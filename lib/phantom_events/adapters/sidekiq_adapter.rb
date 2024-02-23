module PhantomEvents
  module Adapters
    class SidekiqAdapter

      def initialize(listeners_path:,
                     default_queue: :default)
        @listeners_path = listeners_path
        @default_queue = default_queue

        setup_adapter_job_class!
      end

      def handle_event(event_name, *args, **kwargs)
        listeners.each do |listener_klass|
          next unless listener_klass._handles_event?(event_name)

          args.each do |arg|
            arg.stringify_keys! if arg.is_a?(Hash)
          end
          AdapterJob.perform_async(listener_klass.to_s, event_name.to_s, *args, kwargs.to_hash)
        end
      end

      private

      attr_reader :listeners_path, :default_queue

      def listeners
        listeners_path.glob("**/*.rb").map do |pathname|
          relative = pathname.relative_path_from(listeners_path).sub_ext("")
          relative.to_s.classify.safe_constantize
        end
      end

      def setup_adapter_job_class!
        klass = Class.new do
          include Sidekiq::Job

          def perform(klass, event_name, *args, kwargs)
            args.each do |arg|
              arg.with_indifferent_access if arg.is_a?(Hash)
            end
            klass.safe_constantize.new.public_send(event_name, *args, **kwargs)
          end
        end
        klass.sidekiq_options queue: default_queue

        self.class.send(:remove_const, :AdapterJob) if defined?(AdapterJob)
        self.class.const_set(:AdapterJob, klass)
      end
    end
  end
end
