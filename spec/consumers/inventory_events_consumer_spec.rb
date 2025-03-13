# frozen_string_literal: true

require 'rails_helper'

RSpec.describe InventoryEventsConsumer do
  subject(:consumer) { karafka.consumer_for('platform_inventory_events') }
  let(:message) {
    {
      'type' => type,
      'id' => system.id,
      'timestamp' => Time.current.to_s.chomp(' UTC'),
      'platform_metadata' => {
        'org_id' => org_id
      }
    }
  }

  before do
    karafka.produce(message.to_json)
  end

  let(:org_id) { '1234' }
  let(:current_user) { FactoryBot.create(:v2_user) }
  let(:system) do
    FactoryBot.create(
      :system,
      account: current_user.account,
    )
  end

  describe 'when delete message is received' do
    after do
      DeleteHost.clear
    end

    let(:type) { 'delete' }

    it 'enqueues host deletion' do
      expect(Karafka.logger).to receive(:audit_success).with(
        "[#{org_id}] Enqueued DeleteHost job for host #{system.id}"
      )
      expect(Karafka.logger).to receive(:info).with("Received message, enqueueing: #{message}")


      consumer.consume

      expect(DeleteHost.jobs.size).to eq(1)
    end

    context 'enqueued host deletion fails' do
      before do
        allow(DeleteHost).to receive(:perform_async).and_raise(StandardError)
      end

      it 'raises and exception and logs failure' do
        expect(Karafka.logger).to receive(:audit_fail).with(
          "[#{org_id}] Failed to enqueue DeleteHost job for host #{system.id}: StandardError"
        )

        expect { consumer.consume }.to raise_error(StandardError)
      end
    end
  end

  describe 'ReportParsing related message is received' do
    before do
      allow(XccdfReportParser).to receive(:new).and_raise(ActiveRecord::StatementInvalid)
    end

    let(:type) { 'compliance' } # TODO: need platform_metadata => 'service' == compliance

    # TODO: producer changes needed
    it 'handles db errors and db clear connections' do

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
        # expect(ActiveRecord::Base).to receive(:clear_active_connections!)

        expect { consumer.consume }.to raise_error(ActiveRecord::StatementInvalid)

        expect(ParseReportJob.jobs.size).to eq(0)
    end

    it 'handle redis connection problems' do
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

      # @consumer.stubs(:dispatch).raises(Redis::CannotConnectError)

      # assert_raises Redis::CannotConnectError do
      #   @consumer.process(@message)
      # end
    end
  end

  describe 'when unknown message is received' do
    let(:type) { 'somethingelse' }

    it 'does not enqueue any jobs' do
      expect(Karafka.logger).to receive(:debug).with(
        "Skipped message of type #{type}"
      )

      consumer.consume

      expect(DeleteHost.jobs.size).to eq(0)
    end
  end
end
