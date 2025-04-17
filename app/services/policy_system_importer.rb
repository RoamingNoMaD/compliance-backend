# frozen_string_literal: true

# Service for importing a new association between a system and a policy
class PolicySystemImporter
  def initialize(message, logger)
    @message = message
    @logger = logger
  end

  def import_host
    PolicyHost.create!(
      policy_id: policy_id,
      host_id: host_id,
    )
  rescue ActiveRecord::RecordInvalid => e
    @logger.audit_fail(
      "[#{org_id}] Failed to import PolicySystem: #{e.message}"
    )
    raise
  else
    @logger.audit_success(
      "[#{org_id}] Imported PolicySystem for host #{@message[:host_id]}"
    )
  end

  private

  def host_id
    @message.dig('host', 'id')
  end

  def policy_id
    @message.dig('host', 'facts', 'image_builder', 'compliance_policy_id')
  end
end
