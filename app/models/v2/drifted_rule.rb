# frozen_string_literal: true

module V2
  # Model for Drifted Rule
  class DriftedRule < ApplicationRecord
    belongs_to :profile_drift, class_name: 'V2::ProfileDrift'
    belongs_to :rule, class_name: 'V2::Rule'
  end
end
