# frozen_string_literal: true

# Receives messages from the Kafka topic, converts them into jobs for processing
class InventoryEventsConsumer < ApplicationConsumer
  # Raise an error with a cause if a report isn't valid
  class ReportValidationError < StandardError; end

  include ReportParsing

  def consume
    super(messages)
  end

  def consume_one
    dispatch
  rescue Redis::CannotConnectError
    handle_redis_error
  rescue PG::Error, ActiveRecord::StatementInvalid
    handle_db_error
  ensure
    clear!
  end

  def dispatch
    if service == 'compliance'
      handle_report_parsing
    elsif @message['type'] == 'delete'
      handle_host_delete
    else
      logger.debug("Skipped message of type #{@message['type']}")
    end
  end

  def handle_report_parsing
    parse_output = parse_report
    validation_topic = Settings.kafka.topics.upload_compliance
    produce_sync(parse_output, topic: validation_topic) if validation_topic
  end

  def handle_host_delete
    DeleteHost.perform_async(@message)
  rescue StandardError => e
    logger.audit_fail(
      "[#{org_id}] Failed to enqueue DeleteHost job for host #{@message['id']}: #{e}"
    )
    raise
  else
    logger.audit_success(
      "[#{org_id}] Enqueued DeleteHost job for host #{@message['id']}"
    )
  end

  def handle_db_error
    logger.error(
      "[#{org_id}] Database error, clearing active connection for further reconnect"
    )
    ActiveRecord::Base.clear_active_connections! # TODO: ActiveRecord::Base.connection_handler.clear_active_connections!
    # TODO: test if we even need this (issue 4 years ago)
    raise
  end

  def handle_redis_error
    logger.error("[#{org_id}] Failed to connect to elasticache/redis")
    raise
  end

  # NB: This consumer object stays around between messages
  def clear!
    @report_contents
  end

  private

  def account
    @message.dig('platform_metadata', 'account')
  end

  def org_id
    @message.dig('platform_metadata', 'org_id')
  end
end
