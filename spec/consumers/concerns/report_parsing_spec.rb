# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ReportParsing do
  it 'contains a b64_identity' do
    # class TestReportParsing
    #   include ReportParsing

    #   def org_id
    #     '1111'
    #   end

    #   def initialize
    #     @msg_value = {
    #       'platform_metadata' => {
    #         'b64_identity' => 'identity',
    #         'request_id' => 'requestid'
    #       },
    #       'host' => {
    #         'id' => 'id'
    #       }
    #     }
    #   end
    # end

    # assert_equal('identity',
    #              TestReportParsing.new.send(:metadata)['b64_identity'])
    # assert_equal 'id', TestReportParsing.new.send(:metadata)['id']
    # assert_equal 'requestid', TestReportParsing.new.send(:metadata)['request_id']
  end

  it 'enqueues a ParseReportJob' do
    # @message.stubs(:value).returns({
    #   host: {
    #     id: @host.id
    #   },
    #   platform_metadata: {
    #     service: 'compliance',
    #     url: '/tmp/uploads/insights-upload-quarantine/036738d6f4e541c4aa8cf',
    #     request_id: '036738d6f4e541c4aa8cfc9f46f5a140',
    #     org_id: '1111'
    #   }
    # }.to_json)
    # @consumer.stubs(:validated_reports).returns([%w[profileid report]])
    # @consumer.expects(:produce).with(
    #   {
    #     'request_id': '036738d6f4e541c4aa8cfc9f46f5a140',
    #     'service': 'compliance',
    #     'validation': 'success'
    #   }.to_json,
    #   topic: Settings.kafka.topics.upload_compliance
    # )

    # assert_audited_success 'Enqueued report parsing of profileid'
    # @consumer.process(@message)
    # assert_equal 1, ParseReportJob.jobs.size
  end

  it 'notifies payload tracker when a report is received' do
    # @message.stubs(:value).returns({
    #   host: {
    #     id: @host.id
    #   },
    #   platform_metadata: {
    #     service: 'compliance',
    #     url: '/tmp/uploads/insights-upload-quarantine/036738d6f4e541c4aa8cf',
    #     request_id: '036738d6f4e541c4aa8cfc9f46f5a140',
    #     org_id: '1234'
    #   }
    # }.to_json)
    # @consumer.stubs(:download_file)
    # parsed_stub = OpenStruct.new(
    #   test_result_file: OpenStruct.new(
    #     test_result: OpenStruct.new(profile_id: 'profileid')
    #   )
    # )
    # XccdfReportParser.stubs(:new).returns(parsed_stub)
    # @consumer.expects(:produce).with(
    #   {
    #     'request_id': '036738d6f4e541c4aa8cfc9f46f5a140',
    #     'service': 'compliance',
    #     'validation': 'success'
    #   }.to_json,
    #   topic: Settings.kafka.topics.upload_compliance
    # )

    # assert_audited_success 'Enqueued report parsing of profileid'
    # @consumer.process(@message)
  end

  it 'does not leak memory to subsequent messages' do
    # @message.stubs(:value).returns({
    #   host: {
    #     id: @host.id
    #   },
    #   platform_metadata: {
    #     service: 'compliance',
    #     url: '/tmp/uploads/insights-upload-quarantine/036738d6f4e541c4aa8cf',
    #     request_id: '036738d6f4e541c4aa8cfc9f46f5a140',
    #     org_id: '1111'
    #   }
    # }.to_json)
    # @consumer.stubs(:validated_reports).returns([%w[profile report]])
    # @consumer.stubs(:produce)

    # @consumer.process(@message)

    # assert_equal 1, ParseReportJob.jobs.size
    # assert_nil @consumer.instance_variable_get(:@report_contents)
    # assert_nil @consumer.instance_variable_get(:@msg_value)
  end

  it 'passes ssl_only to ReportDownloader' do
    # @message.stubs(:value).returns({
    #   host: {
    #     id: @host.id
    #   },
    #   platform_metadata: {
    #     service: 'compliance',
    #     url: '/tmp/uploads/insights-upload-quarantine/036738d6f4e541c4aa8cf',
    #     request_id: '036738d6f4e541c4aa8cfc9f46f5a140',
    #     org_id: '1111'
    #   }
    # }.to_json)
    # @consumer.stubs(:validated_reports).returns([%w[profileid report]])
    # @consumer.expects(:produce)

    # Settings.expects(:report_download_ssl_only).returns(true)
    # SafeDownloader.expects(:download_reports)
    #               .returns(['report'])
    #               .with do |_url, opts|
    #   opts[:ssl_only] == true
    # end
    # @consumer.process(@message)
  end

  it 'emits notification when ReportDownloader fails' do
    # @message.stubs(:value).returns({
    #   host: {
    #     id: @host.id
    #   },
    #   platform_metadata: {
    #     service: 'compliance',
    #     url: '/tmp/uploads/insights-upload-quarantine/036738d6f4e541c4aa8cf',
    #     request_id: '036738d6f4e541c4aa8cfc9f46f5a140',
    #     org_id: '1234'
    #   }
    # }.to_json)

    # SafeDownloader.stubs(:download_reports).raises(SafeDownloader::DownloadError)

    # ReportUploadFailed.expects(:deliver).with(
    #   host: @host, request_id: '036738d6f4e541c4aa8cfc9f46f5a140', org_id: '1234',
    #   error: "Unable to locate any uploaded report from host #{@host.id}."
    # )

    # @consumer.expects(:produce).with(
    #   {
    #     'request_id': '036738d6f4e541c4aa8cfc9f46f5a140',
    #     'service': 'compliance',
    #     'validation': 'failure'
    #   }.to_json,
    #   topic: Settings.kafka.topics.upload_compliance
    # )

    # assert_audited_fail 'Failed to dowload report'
    # @consumer.process(@message)
    # assert_equal 0, ParseReportJob.jobs.size
  end

  it 'does not emit notification when host is deleted' do
    # @message.stubs(:value).returns({
    #   host: {
    #     id: 'abcdef'
    #   },
    #   platform_metadata: {
    #     service: 'compliance',
    #     url: '/tmp/uploads/insights-upload-quarantine/036738d6f4e541c4aa8cf',
    #     request_id: '036738d6f4e541c4aa8cfc9f46f5a140',
    #     org_id: '1234'
    #   }
    # }.to_json)

    # SafeDownloader.stubs(:download_reports).raises(SafeDownloader::DownloadError)

    # ReportUploadFailed.expects(:deliver).never

    # @consumer.expects(:produce).with(
    #   {
    #     'request_id': '036738d6f4e541c4aa8cfc9f46f5a140',
    #     'service': 'compliance',
    #     'validation': 'failure'
    #   }.to_json,
    #   topic: Settings.kafka.topics.upload_compliance
    # )

    # assert_audited_fail 'Failed to dowload report'
    # @consumer.process(@message)
    # assert_equal 0, ParseReportJob.jobs.size
  end

  it 'does not parse an invalid report' do
    # @message.stubs(:value).returns({
    #   host: {
    #     id: @host.id
    #   },
    #   platform_metadata: {
    #     service: 'compliance',
    #     url: '/tmp/uploads/insights-upload-quarantine/036738d6f4e541c4aa8cf',
    #     request_id: '036738d6f4e541c4aa8cfc9f46f5a140',
    #     org_id: '1234'
    #   }
    # }.to_json)
    # # Mock the actual 'sending the validation' to Kafka
    # XccdfReportParser.stubs(:new).raises(StandardError.new)

    # ReportUploadFailed.expects(:deliver).with(
    #   host: @host, request_id: '036738d6f4e541c4aa8cfc9f46f5a140', org_id: '1234',
    #   error: "Failed to parse any uploaded report from host #{@host.id}: invalid format."
    # )

    # @consumer.expects(:produce).with(
    #   {
    #     'request_id': '036738d6f4e541c4aa8cfc9f46f5a140',
    #     'service': 'compliance',
    #     'validation': 'failure'
    #   }.to_json,
    #   topic: Settings.kafka.topics.upload_compliance
    # )

    # assert_audited_fail 'Invalid Report'
    # @consumer.process(@message)
    # assert_equal 0, ParseReportJob.jobs.size
  end

  it 'does not parse a report with missing entitlement' do
    # Insights::Api::Common::IdentityHeader.stubs(:new).returns(OpenStruct.new(valid?: false))
    # @message.stubs(:value).returns({
    #   host: {
    #     id: '37f7eeff-831b-5c41-984a-254965f58c0f'
    #   },
    #   platform_metadata: {
    #     service: 'compliance',
    #     url: '/tmp/uploads/insights-upload-quarantine/036738d6f4e541c4aa8cf',
    #     request_id: '036738d6f4e541c4aa8cfc9f46f5a140',
    #     org_id: '1234'
    #   }
    # }.to_json)

    # ReportUploadFailed.expects(:deliver).with(
    #   host: @host, request_id: '036738d6f4e541c4aa8cfc9f46f5a140', org_id: '1234',
    #   error: "Failed to parse any uploaded report from host #{@host.id}: " \
    #          'invalid identity of missing insights entitlement.'
    # )

    # @consumer.expects(:validated_reports).never
    # @consumer.expects(:produce).with(
    #   {
    #     'request_id': '036738d6f4e541c4aa8cfc9f46f5a140',
    #     'service': 'compliance',
    #     'validation': 'failure'
    #   }.to_json,
    #   topic: Settings.kafka.topics.upload_compliance
    # )

    # assert_audited_fail 'Rejected report'
    # @consumer.process(@message)
    # assert_equal 0, ParseReportJob.jobs.size
  end
end
