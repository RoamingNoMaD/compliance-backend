# frozen_string_literal: true

# Helper methods related to notifications
module Notifications
  extend ActiveSupport::Concern

  included do
    private

    def compliance_notification_wrapper
      # Store the notification preconditions before saving the report
      preconditions = build_notify_preconditions

      yield

      # Produce a notification if preconditions are met and the new score is below threshold
      return unless parser.supported? && preconditions && parser.score < parser.policy.compliance_threshold

      notify_non_compliant!
      Rails.logger.info('Notification emitted due to non-compliance')
    end

    # Notifications should be only allowed if there are no test results or the policy was previously compliant
    def build_notify_preconditions
      parser.policy&.compliant?(parser.host) || parser.policy&.test_result_hosts&.where(id: parser.host.id)&.empty?
    end

    def notify_non_compliant!
      # FIXME: after rewriting the parser to use V2::Policy, the additional lookup can be removed
      v2_policy = V2::Policy.find_by(id: parser.policy.id)

      SystemNonCompliant.deliver(
        system: parser.host,
        org_id: @msg_value['org_id'],
        policy: v2_policy,
        compliance_score: parser.score
      )
    end
  end
end
