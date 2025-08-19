# frozen_string_literal: true

module V2
  # Service for comparing rules of a tailoring to a target OS minor version's profile rules
  class TailoringRuleComparator
    def initialize(**params)
      @source_tailoring = params[:source_tailoring]
      @target_os_minor_version = params[:target_os_minor_version]
      @diff_only = params[:diff_only]
      @source_rules = @source_tailoring.rules
      @target_rules = @source_tailoring.policy.profile.variant_for_minor(@target_os_minor_version).rules
    end

    def build_comparison
      @source_rules = @source_rules.where.not(id: @target_rules) if @diff_only

      rules_map = {}

      match_rules(rules_map, @source_rules, @source_tailoring.os_minor_version)
      match_rules(rules_map, @target_rules, @target_os_minor_version)

      rules_map.values
    end

    private

    def match_rules(rules_map, rules, os_minor_version)
      rules.each do |rule|
        if rules_map[rule.ref_id]
          rules_map[rule.ref_id][:available_in_versions] << build_rule_version(rule, os_minor_version)
        else
          rules_map[rule.ref_id] = rule.as_json.merge(
            available_in_versions: [build_rule_version(rule, os_minor_version)]
          )
        end
      end
    end

    def build_rule_version(rule, os_minor_version)
      {
        os_major_version: rule.security_guide.os_major_version,
        os_minor_version: os_minor_version,
        ssg_version: rule.security_guide.version
      }
    end
  end
end
