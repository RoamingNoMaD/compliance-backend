# frozen_string_literal: true

# WARNING: this module is already onboarded to APIv2 !!!

module Xccdf
  # Methods related to saving drifted rules
  module DriftedRules
    extend ActiveSupport::Concern

    included do
      def save_drifted_rules
        ::ProfileDrift.import!(profile_drifts, ignore: true)
      end
    end
  end
end
