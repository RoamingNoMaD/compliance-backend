# frozen_string_literal: true

require 'rails_helper'

describe Kafka::ReportParser do
  let(:service) { Kafka::ReportParser.new(message, Karafka.logger) }
  let(:app) { 'compliance' }
  let(:current_user) { FactoryBot.create(:v2_user, :with_cert_auth) }
  let(:org_id) { current_user.org_id }
  let(:request_id) { Faker::Alphanumeric.alphanumeric(number: 32) }
  let(:message) do
    {
      'id' => system.id,
      'b64_identity' => current_user.account.identity_header.raw, # FIXME: too permisive for default
      'host' => {
        'id' => system.id,
        'facts' => { 'image_builder' => { 'compliance_policy_id' => policy.id } },
        'timestamp' => DateTime.now.iso8601(6),
        'org_id' => org_id # NOTE: in the case of host deletion `org_id` is on the top level
      },
      'platform_metadata' => {
        'service' => app,
        'b64_identity' => current_user.account.identity_header.raw, # FIXME: too permisive for default
        'request_id' => request_id
      }
    }
  end
  let(:system) { FactoryBot.create(:system, account: current_user.account) }
  let(:policy) { FactoryBot.create(:v2_policy, account: current_user.account) }

  before do
    allow(SafeDownloader).to receive(:download_reports)
      .with(nil, ssl_only: Settings.report_download_ssl_only)
      .and_return([file_fixture('xccdf_report.xml').read])
  end

  context 'with invalid identity' do
    it 'results in raising entitlement error' do
      expect { service.parse_reports }.to raise_error(Kafka::ReportParser::EntitlementError)
    end
  end

  context 'with failing report download' do
    it 'emits notification' do
      expect(ReportUploadFailed)
        .to receive(:deliver)
        .with(error: 'Unable to locate any uploaded report from host')
      # TODO: verify it produces
      # request_id: id
      # service: compliance
      # validation: failure
      service.parse_reports

      expect(ParseReportJob.jobs.size).to eq(0)
    end
  end

  context 'once report is received' do
    it 'notifies payload tracker' do
      # TODO: verify it produces
      # request_id: id
      # service: compliance
      # validation: success
      service.parse_reports
    end
  end

  context 'with requested system deleted' do
    it 'does not emit notification' do
      # expect(ReportUploadFailed)
      #   .to receive(:deliver).never
      service.parse_reports

      expect(ParseReportJob.jobs.size).to eq(0)
    end
  end

  context 'with empty reports content' do
    it 'raises parse error' do
      expect { service.parse_reports }.to raise_error(Kafka::ReportParser::ReportParseError)
    end
  end

  context 'with unparsable report' do
    it 'raises parse error' do
      expect { service.parse_reports }.to raise_error(Kafka::ReportParser::ReportParseError)
    end
  end

  context 'with parsable reports' do
    it 'enqueues report parsing' do
      expect(Karafka.logger)
        .to receive(:audit_success)
      # .with("[#{org_id}] Enqueued report parsing of ... from request #{request_id} as a job")

      service.parse_reports

      expect(ParseReportJob.jobs.size).to eq(1)
    end
  end

  after do
    ParseReportJob.clear
  end
end
