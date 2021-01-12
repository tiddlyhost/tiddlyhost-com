require_relative "boot"

require "rails"
# Pick the frameworks you want:
require "active_model/railtie"
require "active_job/railtie"
require "active_record/railtie"
require "active_storage/engine"
require "action_controller/railtie"
require "action_mailer/railtie"
# require "action_mailbox/engine"
# require "action_text/engine"
require "action_view/railtie"
# require "action_cable/engine"
require "sprockets/railtie"
require "rails/test_unit/railtie"

# Our custom settings handler. We have to load it early so the
# settings can be used while we're still starting up rails.
require_relative '../lib/settings'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module App
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 6.1

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")

    config.eager_load_paths << Rails.root.join("lib")

    # Support our wildcard subdomains
    config.hosts << ".#{Settings.url_defaults[:host]}"
    config.session_store :cookie_store, domain: Settings.url_defaults[:host]
    config.action_controller.default_url_options = { host: Settings.url_defaults[:host] }

    # Initially for devise emails
    config.action_mailer.default_url_options = Settings.url_defaults

    # For uploads..?
    config.action_controller.forgery_protection_origin_check = false

  end
end
