# frozen_string_literal: true

module V2
  # Model for Profile Drift
  class ProfileDrift < ApplicationRecord
    has_many :drifted_rules, class_name: 'V2::DriftedRule', dependent: :destroy

    belongs_to :base_profile, class_name: 'V2::Profile', foreign_key: { to_table: :profiles }
    belongs_to :target_profile, class_name: 'V2::Profile', foreign_key: { to_table: :profiles }
  end
end
