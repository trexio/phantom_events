# frozen_string_literal: true

require_relative 'phantom_events/version'
require_relative 'phantom_events/configuration'
require_relative 'phantom_events/publisher'
require_relative 'phantom_events/listener'

module PhantomEvents
  class Error < StandardError; end

  def self.config
    @@config
  end

  def self.configure(&block)
    if defined?(::Rails)
      Rails.application.config.to_prepare do
        @@config = Configuration.new(&block)
      end
    else
      @@config = Configuration.new(&block)
    end
  end
end
