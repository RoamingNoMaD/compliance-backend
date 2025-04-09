# frozen_string_literal: true

class KarafkaApp < Karafka::App
  # librdkafka config creation
  security_protocol = Settings.kafka.security_protocol.downcase

  if security_protocol == 'sasl_ssl'
    sasl_config = {
      'sasl.username': Settings.kafka.sasl_username,
      'sasl.password': Settings.kafka.sasl_password,
      'sasl.mechanism': Settings.kafka.sasl_mechanism,
      'security.protocol': Settings.kafka.security_protocol
    }
  else
    sasl_config = {}
  end

  ca_location = Settings.kafka.ssl_ca_location if %w[ssl sasl_ssl].include?(security_protocol)

  kafka_config = {
    'bootstrap.servers': Settings.kafka.brokers,
    'ssl.ca.location': ca_location
  }.merge(sasl_config).compact

  setup do |config|
    config.kafka = kafka_config
    config.client_id = 'compliance_backend'
    config.consumer_persistence = !Rails.env.development?
  end

  Karafka.monitor.subscribe(
    Karafka::Instrumentation::LoggerListener.new(
      log_polling: true
    )
  )

  Karafka.producer.monitor.subscribe(
    WaterDrop::Instrumentation::LoggerListener.new(
      Karafka.logger,
      log_messages: false
    )
  )

  routes.draw do
    topic Settings.kafka.topics.inventory_events do
      consumer InventoryEventsConsumer
    end
  end
end
