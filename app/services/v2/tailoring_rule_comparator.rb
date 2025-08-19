# frozen_string_literal: true

module V2
  # Service for comparing rules of a tailoring to a target OS minor version's profile rules
  class TailoringRuleComparator
    def initialize(**params)
      source_tailoring = params[:source_tailoring]
      target_os_minor_version = params[:target_os_minor_version]

      source_rules = source_tailoring.rules
      target_rules = source_tailoring.policy.profile.variant_for_minor(target_os_minor_version).rules

      source_rules = source_rules.where.not(id: target_rules) if params[:diff_only]

      @all_rules = [
        source_rules.map { |rule| [rule, source_tailoring.os_minor_version] },
        target_rules.map { |rule| [rule, target_os_minor_version] }
      ].flatten(1)
    end

    def build_comparison
      @all_rules.group_by { |rule, _os_minor_version| rule.ref_id }.map do |_, rule_data|
        current_rule = rule_data.first[0]
        available_in_versions = rule_data.map { |rule, os_minor_version| build_rule_version(rule, os_minor_version) }

        current_rule.as_json.merge(available_in_versions: available_in_versions)
      end
    end

    private

    def build_rule_version(rule, os_minor_version)
      {
        os_major_version: rule.security_guide.os_major_version,
        os_minor_version: os_minor_version,
        ssg_version: rule.security_guide.version
      }
    end
  end
end
