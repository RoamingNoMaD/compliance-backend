# frozen_string_literal: true

require 'rails_helper'

# TODO: maybe there's no need to separate parsing and validation?
# maybe separate based on different concerns?
RSpec.describe Validation do
  it 'raises an exception when report is missing' do
    # test 'fails if no reports in the uploaded archive' do
    #   class TestValidation
    #     include Validation
    #   end

    #   assert_raises InventoryEventsConsumer::ReportValidationError do
    #     TestValidation.new.validated_reports([], {})
    #   end
    # end
  end
end
