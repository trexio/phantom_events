module PhantomEvents
  module Adapters
    class ActiveJobAdapter
      def initialize(listeners_path:,
                     parent_class: ActiveJob::Base,
                     default_queue: :default,
                     retries: 5,
                     retry_interval: 5)
        @listeners_path = listeners_path
        @parent_class = parent_class
        @default_queue = default_queue
        @retries = retries
        @retry_interval = retry_interval # ignored with sidekiq queue_adapter

        setup_adapter_job_class!
      end

      def handle_event(event_name, *args, **kwargs)
        listeners.each do |listener_klass|
          next unless listener_klass._handles_event?(event_name)

          binding.pry if listener_klass.__enqueue_options.nil?
          queue = listener_klass.__enqueue_options[:queue] || default_queue

          AdapterJob
            .set(queue:)
            .perform_later(listener_klass, event_name, *args, **kwargs)
        end
      end

      private

      attr_reader :listeners_path, :parent_class, :default_queue, :retries,
                  :retry_interval

      def listeners
        listeners_path.glob("**/*.rb").map do |pathname|
          relative = pathname.relative_path_from(listeners_path).sub_ext("")
          relative.to_s.classify.safe_constantize
        end.compact.select { |klass| klass.include?(PhantomEvents::Listener) }
      end

      def setup_adapter_job_class!
        klass = Class.new parent_class do
          def perform(klass, event_name, *args, **kwargs)
            klass.new._handle_event(event_name, *args, **kwargs)
          end
        end
        klass.queue_as default_queue

        if Rails.application.config.active_job.queue_adapter == :sidekiq
          klass.retry_on StandardError, attempts: 0
          klass.sidekiq_options retry: retries
        else
          klass.retry_on StandardError, wait: retry_interval,
                                        attempts: retries
        end

        self.class.send(:remove_const, :AdapterJob) if defined?(AdapterJob)
        self.class.const_set(:AdapterJob, klass)
      end
    end
  end
end
