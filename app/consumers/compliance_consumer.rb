# frozen_string_literal: true

# Receives messages from the Kafka topic, dispatches them to the appropriate service
class ComplianceConsumer < ApplicationConsumer
  def consume_one
    if message_type == 'delete'
      HostRemover.new(@message, logger).remove_host
    else
      logger.debug "Skipped message of type #{message_type}"
    end
  end

  private

  def service
    @message.dig('platform_metadata', 'service')
  end

  def message_type
    @message.dig('type')
  end
end
