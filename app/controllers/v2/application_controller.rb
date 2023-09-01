# frozen_string_literal: true

module V2
  # General controller to include all-encompassing behavior
  class ApplicationController < ::ActionController::API
    SEARCH = :filter

    include ::ActionController::Helpers
    include ::Pundit::Authorization
    include ::Authentication
    include ::ExceptionNotifierCustomData
    include V2::Metadata
    include V2::Pagination
    include V2::Collection
    include ::Rendering
    include V2::ParameterHandling
    include ::ErrorHandling

    before_action :set_csp_hsts

    class << self
      def permission_for_action(action, permission)
        @action_permissions ||= {}
        @action_permissions[action.to_sym] ||= permission
      end
    end

    def pundit_scope
      Pundit.policy_scope(current_user, resource)
    end

    # This method is being called before any before_action callbacks and it can set
    # payload information for the metrics collector. As the User.current is not yet
    # available at this moment, a short path to the org_id is being used to pass it
    # to the payload if set.
    #
    # https://github.com/yabeda-rb/yabeda-rails#custom-tags
    def append_info_to_payload(payload)
      super

      return if identity_header.blank?

      payload[:qe] = OpenshiftEnvironment.qe_account?(identity_header.org_id)
    end

    protected

    def audit_success(msg)
      Rails.logger.audit_success(msg)
    end

    def set_csp_hsts
      response.set_header('Content-Security-Policy', "default-src 'none'")
      response.set_header('Strict-Transport-Security', "max-age=#{1.year}")
    end

    def rbac_allowed?
      return valid_cert_auth? if identity_header.cert_based?

      permission = self.class.instance_variable_get(:@action_permissions)[action_name.to_sym]
      user.authorized_to?(Rbac::INVENTORY_HOSTS_READ) && user.authorized_to?(permission)
    end

    # Reduce through all the parents of the resource and join+scope them on the resource
    # or return with the resource untouched if not nested under other resources
    def expand_resource
      permitted_params[:parents].to_a.reduce(resource) do |scope, parent|
        ref = scope.reflect_on_association(parent)
        klass = ref.klass

        scope.joins(parent)
             .where(parent => { klass.primary_key => permitted_params[ref.foreign_key] })
             .merge(Pundit.policy_scope(current_user, klass))
      end
    end
  end
end