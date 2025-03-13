# frozen_string_literal: true

require 'rails_helper'

RSpec.describe InventoryEventsConsumer do
  # This will create a consumer instance with all the settings defined for the given topic
  subject(:consumer) { karafka.consumer_for('platform_inventory_events') } # TODO: correct topic? (validation??)

  before do
    karafka.produce({
      'type' => type,
      'id' => system.id,
      'timestamp' => Time.current.to_s.chomp(' UTC') # TODO: consider including timezone or find a better solution
    }.to_json)

    allow(Karafka.logger).to receive(:info)
  end

  let(:current_user) { FactoryBot.create(:v2_user) }
  let(:system) do
    FactoryBot.create(
      :system,
      account: current_user.account,
    )
  end

  #   expect(Karafka.logger).to receive(:info).with("Sum of 2 elements equals to: #{sum}")
  #   consumer.consume_one
  # end

  describe 'when delete message is received' do
    after do # TODO: necessary?
      DeleteHost.clear
    end

    # it 'expects to log a proper message' do
    let(:type) { 'delete' }

    it 'enqueues host deletion' do
      expect(Karafka.logger).to receive(:info).with("Enqueued DeleteHost job for host #{system.id}")

      consumer.consume_one

      expect(DeleteHost.jobs.size).to eq(0)

      # assert_audited_success('Enqueued DeleteHost job for host fe314be5-4091-412d-85f6-00cc68fc001b')
      # @consumer.process(@message)
      # assert_equal 1, DeleteHost.jobs.size
    end

    context 'enqueued host deletion fails' do # TODO: Not sure about nesting context like this
      it 'raises and exception' do
        # @message.expects(:value).returns(
        #   '{"type": "delete", ' \
        #   '"id": "fe314be5-4091-412d-85f6-00cc68fc001b", ' \
        #   '"timestamp": "2019-05-13 21:18:15.797921"}'
        # ).at_least_once
        # DeleteHost.stubs(:perform_async).raises(:StandardError)
        # assert_raises StandardError do
        #   assert_audited_fail 'Failed to enqueue DeleteHost job for host fe314be5-4091-412d-85f6-00cc68fc001b:'
        #   @consumer.process(@message)
        # end
      end
    end
  end

  describe 'when unknown message is received' do
    let(:type) { 'somethingelse' }

    it 'does not enqueue any jobs' do
      # @message.expects(:value).returns(
      #   '{"type": "somethingelse", ' \
      #   '"id": "fe314be5-4091-412d-85f6-00cc68fc001b", ' \
      #   '"timestamp": "2019-05-13 21:18:15.797921"}'
      # ).at_least_once
      # @consumer.process(@message)
      # assert_equal 0, DeleteHost.jobs.size
    end
  end

  describe 'ReportParsing related message is received' do # TODO: `report upload message received`?
    let(:type) { 'compliance' } # TODO: correct type?

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
      # # Mock the actual 'sending the validation' to Kafka
      # XccdfReportParser.stubs(:new).raises(ActiveRecord::StatementInvalid)

      # ActiveRecord::Base.expects(:clear_active_connections!)
      # assert_raises ActiveRecord::StatementInvalid do
      #   @consumer.process(@message)
      # end
      # assert_equal 0, ParseReportJob.jobs.size
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
end
