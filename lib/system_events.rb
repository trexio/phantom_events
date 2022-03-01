# frozen_string_literal: true

require_relative 'system_events/version'
require_relative 'system_events/configuration'
require_relative 'system_events/publisher'

module SystemEvents
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
