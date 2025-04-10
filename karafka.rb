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

    # Allow Rails code reload to work in dev env.
    config.consumer_persistence = !Rails.env.development?
  end

  # Comment out this part if you are not using instrumentation and/or you are not
  # interested in logging events for certain environments. Since instrumentation
  # notifications add extra boilerplate, if you want to achieve max performance,
  # listen to only what you really need for given environment.
  Karafka.monitor.subscribe(
    Karafka::Instrumentation::LoggerListener.new(
      # Karafka, when the logger is set to info, produces logs each time it polls data from an
      # internal messages queue. This can be extensive, so you can turn it off by setting below
      # to false.
      log_polling: true
    )
  )
  # Karafka.monitor.subscribe(Karafka::Instrumentation::ProctitleListener.new)

  # This logger prints the producer development info using the Karafka logger.
  # It is similar to the consumer logger listener but producer oriented.
  Karafka.producer.monitor.subscribe(
    WaterDrop::Instrumentation::LoggerListener.new(
      # Log producer operations using the Karafka logger
      Karafka.logger,
      # If you set this to true, logs will contain each message details
      # Please note, that this can be extensive
      log_messages: false
    )
  )

  # You can subscribe to all consumer related errors and record/track them that way
  #
  # Karafka.monitor.subscribe 'error.occurred' do |event|
  #   type = event[:type]
  #   error = event[:error]
  #   details = (error.backtrace || []).join("\n")
  #   ErrorTracker.send_error(error, type, details)
  # end

  # You can subscribe to all producer related errors and record/track them that way
  # Please note, that producer and consumer have their own notifications pipeline so you need to
  # setup error tracking independently for each of them
  #
  # Karafka.producer.monitor.subscribe('error.occurred') do |event|
  #   type = event[:type]
  #   error = event[:error]
  #   details = (error.backtrace || []).join("\n")
  #   ErrorTracker.send_error(error, type, details)
  # end

  routes.draw do
    # Uncomment this if you use Karafka with ActiveJob
    # You need to define the topic per each queue name you use
    # active_job_topic :default

    # TODO: verify and maybe use this
    # Settings.kafka.topics.each do |t|
    #   topic t do
    #     consumer InventoryEventsConsumer
    #   end
    # end

    topic Settings.kafka.topics.inventory_events do
      # Uncomment this if you want Karafka to manage your topics configuration
      # Managing topics configuration via routing will allow you to ensure config consistency
      # across multiple environments
      #
      # config(partitions: 2, 'cleanup.policy': 'compact')
      consumer ComplianceConsumer
    end

  end
end
