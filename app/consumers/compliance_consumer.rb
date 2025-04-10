# frozen_string_literal: true

# Receives messages from the Kafka topic, converts them into jobs for processing
class ComplianceConsumer < ApplicationConsumer
  include SystemRemoval

  def consume_one
    if type == 'delete'
      delete_system
    end
  end

  private

  def account
    @message.dig('platform_metadata', 'account')
  end

  def org_id
    @message.dig('platform_metadata', 'org_id')
  end
end
