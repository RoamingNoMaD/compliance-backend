# frozen_string_literal: true

module V2
  # Model for Migration
  class Migration
    include ActiveModel::API

    include V2::Searchable
    include V2::Indexable
    include V2::Sortable

    attr_accessor :tailoring, :target_os_minor, :diff_only

    class InvalidTargetVersionError < StandardError; end

    AN = Arel::Nodes

    def self.table_name
      'migrations'
    end

    def self.primary_key
      'id'
    end

    def model_name
      ActiveModel::Name.new(self, nil, 'migration')
    end

    sortable_by :title

    searchable_by :title, %i[like unlike eq ne]

    def initialize(attributes={})
      super

      @tailoring = attributes[:tailoring]
      @target_os_minor = attributes[:params][:target_os_minor]
      @diff_only = attributes[:params][:diff_only]

      ensure_higher_os_minor_version

      @base_profile = tailoring.profile
      @target_profile = tailoring.profile.variant_for_minor(@target_os_minor)
    end

    def build_migration
      base_rules = selected_profile_rules(@base_profile, @tailoring.os_minor_version)
      target_rules = selected_profile_rules(@target_profile, @target_os_minor)

      if @diff_only
        target_rules = target_rules.where.not(ref_id: base_rules.select(:ref_id))
      end

      union_query = base_rules.arel.union(target_rules.arel)

      V2::Rule.find_by_sql(union_query.to_sql)
    end

    private

    def selected_profile_rules(profile, os_minor_version)
      V2::Rule.select(
        V2::Rule.arel_table[:id, :ref_id, :title],
        selected_case_statement.as('selected'),
        build_available_versions(profile.security_guide, os_minor_version).as('available_in_versions')
      ).joins(
        profile_rules_join
      ).where(
        V2::ProfileRule.arel_table[:profile_id].eq(profile.id)
      )
    end

    def selected_case_statement
      AN::Case.new.when(
        V2::TailoringRule.arel_table[:tailoring_id].eq(@tailoring.id)
      ).then(true).else(false)
    end

    def build_available_versions(security_guide, os_minor_version)
      AN::Quoted.new(
        {
          os_major_version: security_guide.os_major_version,
          os_minor_version: os_minor_version,
          ssg_version: security_guide.version
        }.to_json
      )
    end

    def profile_rules_join
      profile_rules_table = V2::ProfileRule.arel_table
      tailoring_rules_table = V2::TailoringRule.arel_table

      rt = V2::Rule.arel_table

      rt.join(profile_rules_table)
        .on(profile_rules_table[:rule_id].eq(rt[:id]))
        .join(tailoring_rules_table, AN::OuterJoin)
        .on(tailoring_rules_table[:rule_id].eq(rt[:id]))
        .join_sources
    end

    def ensure_higher_os_minor_version
      if @target_os_minor <= @tailoring.os_minor_version
        raise InvalidTargetVersionError, 'Target OS minor version must be higher than the tailoring OS minor version'
      end
    end
  end
end
