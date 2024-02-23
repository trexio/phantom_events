module PhantomEvents
  module Adapters
    class AmqpAdapter

      def initialize(dsn: ENV['RABBITMQ_URL'], exchange_name: :events)
        @dsn = dsn
        @exchange_name = exchange_name
      end

      def handle_event(event_name, *args, **kwargs)
        if args.last.is_a?(Hash) && kwargs.empty?
          kwargs = args.pop.symbolize_keys!
        end

        message = {
          event_name: event_name,
          args:       args,
          kwargs:     kwargs
        }.to_json

        exchange.publish(message)
      end

      # def handles_event?(_)
      #   true
      # end

      private

      attr_accessor :dsn, :exchange_name

      def exchange
        @exchange ||= channel.fanout(exchange_name.to_s, durable: true)
      end

      def channel
        @channel ||= connection.create_channel
      end

      def connection
        @connection ||= Bunny.new(dsn).tap(&:start)
      end
    end
  end
end
