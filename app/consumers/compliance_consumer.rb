# frozen_string_literal: true

# Receives messages from the Kafka topic, converts them into jobs for processing
class ComplianceConsumer < ApplicationConsumer

  private

  def account
    @message.dig('platform_metadata', 'account')
  end

  def org_id
    @message.dig('platform_metadata', 'org_id')
  end
end
