# frozen_string_literal: true

require_relative 'boot'

require 'rails'
# Pick the frameworks you want:
require 'active_model/railtie'
require 'active_job/railtie'
require 'active_record/railtie'
# require 'active_storage/engine'
require 'action_controller/railtie'
# require 'action_mailer/railtie'
# require 'action_mailbox/engine'
# require 'action_text/engine'
# require 'action_view/railtie'
# require 'action_cable/engine'
# require 'sprockets/railtie'
require 'rails/test_unit/railtie'
require 'clowder-common-ruby/engine'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

# (Development/Test env only)
# Load .env* variables before the config (Settings) initializer is
# being run.
Dotenv::Rails.load unless Rails.env.production?

module ComplianceBackend
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 8.0

    # Partial inserts are necessary for writing into views with read-only fields
    config.active_record.partial_inserts = true # FIXME: clean up after the remodel

    # Load platform modules
    require 'insights'

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration can go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded after loading
    # the framework and any gems in your application.

    # Only loads a smaller set of middleware suitable for API only apps.
    # Middleware like session, flash, cookies can be added back manually.
    # Skip views, helpers and assets when generating a new resource.
    config.api_only = true
    config.active_job.queue_adapter = :sidekiq

    # Tag log messages with org_id when available
    config.log_tags = [
      :request_id,
      -> request { Insights::Api::Common::IdentityHeader.from_request(request)&.org_id }
    ]


    # Adjust params[tags] to be array
    config.middleware.use Insights::Api::Common::AdjustTags::Middleware
    # Compensate the missing MIME type in Satellite-forwarded requests
    config.middleware.use Insights::Api::Common::SatelliteCompensation::Middleware
  end
end
