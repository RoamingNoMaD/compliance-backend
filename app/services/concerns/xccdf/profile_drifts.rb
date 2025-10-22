# frozen_string_literal: true

# WARNING: this module is already onboarded to APIv2 !!!

module Xccdf
  # Methods related to saving profile drifts
  module ProfileDrifts
    extend ActiveSupport::Concern

    included do
      def profile_drifts
        @profile_drifts ||= @op_profiles.flat_map do |op_profile|
          op_profile.drifted_rules.map do |drifted_rule|
            ::ProfileDrift.new(profile_id: op_profile.id, rule_id: drifted_rule.id)
          end
        end
      end

      def save_profile_drifts
        ::ProfileDrift.import!(profile_drifts, ignore: true)
      end
    end
  end
end
