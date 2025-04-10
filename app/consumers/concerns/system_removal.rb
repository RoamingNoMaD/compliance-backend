# frozen_string_literal: true

module SystemRemoval
  extend ActiveSupport::Concern

  included do
    def delete_system
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
  end
end
