# frozen_string_literal: true

# Parent class for all Karafka consumers, contains general logic
class ApplicationConsumer < Karafka::BaseConsumer
  attr_reader :msg_value
  def consume
    messages.each do |message|
      @message = JSON.parse(message.raw_payload) # TODO: raw_payload vs value

      consume_one

      logger.info "Received message, enqueueing: #{@msg_value}"

      mark_as_consumed(message)
    end
  end

  protected

  def logger
    Rails.logger
  end
end
