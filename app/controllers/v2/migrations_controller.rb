# frozen_string_literal: true

module V2
  # API for Migrations between rulesets of Tailorings and Profiles
  class MigrationsController < ApplicationController
    # TODO: needed?
    # include V2::ArbitraryCollection

    COMPARISON_ATTRIBUTES = {
      target_os_minor: ParamType.integer & ParamType.gte(0).required,
      diff_only: ParamType.boolean
    }.freeze

    class InvalidTargetVersionError < StandardError; end

    def index
      render_json migrations, status: :ok
    rescue V2::Migration::InvalidTargetVersionError => e
      render_error e.message, status: :unprocessable_entity
    end
    permission_for_action :index, Rbac::POLICY_READ
    permitted_params_for_action :index, {
      policy_id: ID_TYPE,
      tailoring_id: ID_TYPE,
      **COMPARISON_ATTRIBUTES
    }

    private

    def tailoring
      @tailoring ||= pundit_scope(V2::Tailoring).find(permitted_params[:tailoring_id])
    end

    def migrations
      @migrations ||= V2::Migration.new(
        tailoring: tailoring,
        target_os_minor: permitted_params[:target_os_minor],
        diff_only: permitted_params[:diff_only]
      ).build_migration
    end

    def resource
      V2::Tailoring
    end

    def serializer
      V2::MigrationSerializer
    end

    def extra_fields
      %i[tailoring_id]
    end
  end
end
