# frozen_string_literal: true

module Kafka
  # Consumer concerns related to report parsing
  class ReportParser
    # Raise an error if entitlement is not available
    class EntitlementError < StandardError; end
    # Raise an error if parsing report is not possible
    class ReportParseError < StandardError; end

    def initialize(message, logger)
      @message = message
      @logger = logger
    end

    # rubocop:disable Metrics/AbcSize
    def parse_reports
      raise EntitlementError unless identity.valid?
      raise ReportParseError if reports.empty?

      # Map successfuly parsed (validated) reports by scanned profile
      parsed_reports = reports.map do |xml|
        [parse(xml).test_result_file.test_result.profile_id, xml]
      end

      # Evaluate each report individually and notify abut the result
      parsed_reports.each_with_index do |(profile_id, _report), idx|
        job = ParseReportJob.perform_async(idx, metadata)
        notify_report_success(profile_id, job)
        # TODO: replace with `process_report(profile_id, report)`
        #       to get rid of Sidekiq
      end

      produce_validation_message('success')
    end
    # rubocop:enable Metrics/AbcSize

    private

    def notify_report_success(profile_id, job)
      msg = "Enqueued report parsing of #{profile_id} from request #{request_id} as job #{job}"
      @logger.audit_success("[#{org_id}] #{msg}")
      notify_payload_tracker(:received, "File of #{profile_id} is valid. Job #{job} enqueued")
    end

    def notify_payload_tracker(status, status_msg = '')
      PayloadTracker.deliver(
        account: account, system_id: @message['id'],
        request_id: request_id, status: status,
        status_msg: status_msg, org_id: org_id
      )
    end

    def reports
      @reports ||= SafeDownloader.download_reports(url, ssl_only: Settings.report_download_ssl_only)
    rescue SafeDownloader::DownloadError => e
      parse_error(e)
    end

    def identity
      Insights::Api::Common::IdentityHeader.new(b64_identity)
    end

    def metadata
      @message.dig('platform_metadata') || {}
    end

    def account
      metadata.dig('account')
    end

    def b64_identity
      metadata.dig('b64_identity')
    end

    def request_id
      metadata.dig('request_id')
    end

    def org_id
      metadata.dig('org_id')
    end

    def url
      metadata.dig('url')
    end

    def parse(xml)
      XccdfReportParser.new(xml, @message)
    rescue PG::Error, ActiveRecord::StatementInvalid => e
      parse_error(e)
    rescue StandardError
      raise ReportParseError
    end

    def produce_validation_message(result)
      # TODO: send this message to validation topic, if present
      {
        'request_id': request_id,
        'service': 'compliance',
        'validation': result
      }
    end

    # TODO: uncomment to get rid of Sidekiq
    #
    # def process_report(profile, report)
    #   @logger.info "Processing #{profile} report #{report}"

    #   # Storing notification preconditions before saving the report
    #   should_notify = notifications_allowed?(report)

    #   # Evaluate compliance of the report
    #   if report_compliant?(report)
    #     report.save_all
    #   else
    #     if should_notify
    #       @logger.info('Emitting notification due to non-compliance')
    #       notify_non_compliant!
    #     end
    #   end

    #   notify_remediation(report)
    #   parse_success(report, profile)
    # end

    # def report_compliant?(report)
    #   report.supported? && report.score >= report.policy.compliance_threshold
    # end

    # def notifications_allowed?(report)
    #   previously_compliant = report.policy&.compliant?(report.system)
    #   no_test_results = report.policy&.test_result_systems&.where(id: report.system.id)&.empty?

    #   previously_compliant || no_test_results
    # end

    # def notify_non_compliant!(report)
    #   SystemNonCompliant.deliver(
    #     system: report.system,
    #     org_id: @message['org_id'],
    #     policy: report.policy,
    #     policy_threshold: report.policy.compliance_threshold,
    #     compliance_score: report.score
    #   )
    # end

    # def notify_remediation(report)
    #   RemediationUpdates.deliver(
    #     system_id: @message['id'],
    #     issue_ids: remediation_issue_ids(report)
    #   )
    # end

    # def remediation_issue_ids(report)
    #   report.failed_rules
    #         .includes(profiles: :benchmark)
    #         .collect(&:remediation_issue_id)
    #         .compact
    # end

    # def parse_success(report, profile)
    #   msg = "[#{org_id}] Successfull report of #{profile} " \
    #         "for policy #{report.system_profile.policy_id} " \
    #         "from system #{@message['id']}"
    #   @logger.audit_success msg
    #   produce_validation_message('success')
    # end

    # def parse_error(exception)
    #   msg = "[#{org_id}] #{exception_message(exception)}"
    #   @logger.error msg
    #   @logger.audit_fail msg
    #   produce_validation_message('failed')
    # end

    # def exception_message(e)
    #   case e
    #   when EntitlementError
    #     "Rejected report with request id #{request_id}: invalid identity or missing insights entitlement"
    #   when SafeDownloader::DownloadError
    #     "Failed to dowload report with request id #{request_id}: #{e.message}"
    #   when ReportParseError
    #     "Invalid report: #{e.cause.message}"
    #   else
    #     "Error parsing report: #{request_id} - #{e.message}"
    #   end
    # end

    # TODO: consider creating Report class with attribute 'profile' and 'raw'
    #       to encapsulate methods working with parsed report
    #
    #       ParsedReport
    #       ---
    #       + profile
    #       + raw
    #       ---
    #       + process
    #       - report_compliant?
    #       - allows_notification? # why should we need to store it before 'report.save_all'
  end
end
