module PhantomEvents
  module Listener

    def self.included(base)
      base.extend(ClassMethods)
      base.instance_variable_set(:@__enqueue_options, {})
      base.singleton_class.class_eval do
        def inherited(subclass)
          super
          subclass.instance_variable_set(:@__enqueue_options, {})
        end
      end
    end

    def _handle_event(event_name, *args, **kwargs)
      return unless self.class._handles_event?(event_name)

      matched_kwargs = kwargs.symbolize_keys!.slice(*_matched_kwargs_keys(event_name, **kwargs))

      public_send(event_name, *args, **matched_kwargs)
    end

    def _matched_kwargs_keys(event_name, **kwargs)
      kwargs = kwargs.symbolize_keys!
      method_params = method(event_name).parameters
      return kwargs.keys if method_params.any? { |type, _| type == :keyrest }

      method_kwargs_keys = method_params.select do |type, _|
        %i[keyreq key].include?(type)
      end.map(&:last)

      kwargs.keys & method_kwargs_keys
    end

    module ClassMethods
      attr_reader :__enqueue_options

      def enqueue_options(queue: nil)
        @__enqueue_options = { queue: }
      end

      def _handles_event?(event_name)
        instance_methods.include?(event_name.to_sym)
      end
    end
  end
end
