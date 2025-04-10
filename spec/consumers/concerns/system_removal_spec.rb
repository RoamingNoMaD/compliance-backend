# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'SystemRemoval' do
  class TestConsumer
    include SystemRemoval

    def initialize(message)
      @message = message
    end

    def org_id
      @message['org_id']
    end

    def logger
      logger = Karafka.logger
    end

    def consume
      delete_system
    end
  end

  after do
    DeleteHost.clear
  end

  let(:type) { 'delete' }
  let(:user) { FactoryBot.create(:v2_user) }
  let(:org_id) { user.org_id }
  let(:system) {
    FactoryBot.create(
      :system,
      account: user.account,
    )
  }
  let(:message) {{
    'type' => type,
    'id' => system.id,
    'timestamp' => Time.current.to_s.chomp(' UTC'),
    'org_id' => org_id # in the case of host deletion `org_id` is on the top level
  }}

  let(:consumer) { TestConsumer.new(message) }

  it 'enqueues system deletion' do
    expect(Karafka.logger).to receive(:audit_success).with(
      "[#{org_id}] Enqueued DeleteHost job for host #{system.id}"
    )

    consumer.consume

    expect(DeleteHost.jobs.size).to eq(1)
  end

  context 'enqueued system deletion fails' do
    before do
      allow(DeleteHost).to receive(:perform_async).and_raise(StandardError)
    end

    it 'handles error gracefully' do
      expect(Karafka.logger).to receive(:audit_fail).with(
        "[#{org_id}] Failed to enqueue DeleteHost job for host #{system.id}: StandardError"
      )

      expect { consumer.consume }.to raise_error(StandardError)
      expect(DeleteHost.jobs.size).to eq(0)
    end
  end
end
