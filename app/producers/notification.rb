# frozen_string_literal: true

# A Kafka producer client for notifications
class Notification < ApplicationProducer
  TOPIC = Settings.kafka.topics.notifications_ingress
  EVENT_TYPE = nil
  BUNDLE = 'rhel'
  VERSION = 'v1.1.0'

  # rubocop:disable Metrics/MethodLength
  def self.deliver(org_id:, **)
    msg = {
      version: VERSION,
      bundle: BUNDLE,
      application: SERVICE,
      event_type: self::EVENT_TYPE,
      timestamp: DateTime.now.iso8601,
      org_id: org_id,
      events: build_events(**),
      context: build_context(**).to_json,
      recipients: []
    }

    kafka&.produce_sync(payload: msg.to_json, topic: self::TOPIC)
  rescue *EXCEPTIONS => e
    logger.error("Notification delivery failed: #{e}")
  end
  # rubocop:enable Metrics/MethodLength

  def self.build_context(system:, **_kwargs)
    {
      display_name: system&.display_name,
      host_url: "https://console.redhat.com/insights/inventory/#{system&.id}",
      inventory_id: system&.id,
      rhel_version: [system&.os_major_version, system&.os_minor_version].join('.'),
      tags: system&.tags
    }
  end
end
