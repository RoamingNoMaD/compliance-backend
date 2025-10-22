# frozen_string_literal: true

module V2
  # Model for SCAP policies
  class ProfileComparison < ApplicationRecord

    belongs_to :base_profile, class_name: 'V2::Profile'
    belongs_to :security_guide, class_name: 'V2::SecurityGuide'

    has_one :target_profile, class_name: 'V2::Profile'


  end
end
