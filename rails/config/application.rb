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
require_relative "../lib/settings"

# Our custom logger
require_relative "../app/middleware/logger_with_domain"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module App
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    # Todo: Should be updated soon
    config.load_defaults 6.1

    # https://guides.rubyonrails.org/upgrading_ruby_on_rails.html#new-activesupport-cache-serialization-format
    # Todo: Should be removed carefully
    config.active_support.cache_format_version = 7.0

    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    # Common ones are `templates`, `generators`, or `middleware`, for example.
    config.autoload_lib(ignore: %w[assets tasks])

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")

    config.eager_load_paths.concat(%w[
      app/middleware
      lib
    ].map do |path|
      Rails.root.join(path).to_s
    end)

    config.autoload_lib(ignore: %w[assets tasks])

    # For tiddlyhost and its wildcard subdomains
    config.hosts << Settings.main_site_host
    config.hosts << ".#{Settings.main_site_host}"

    # For tiddlyspot and its wildcard subdomains
    if Settings.tiddlyspot_host.present?
      config.hosts << Settings.tiddlyspot_host
      # Need the regex because some tiddlyspot site names have
      # dots and underscores which wouldn't be matched otherwise
      config.hosts << /.+\.#{Regexp.escape(Settings.tiddlyspot_host)}/
    end

    # (`domain: :all` might be useful here later maybe)
    config.session_store :cookie_store, domain: Settings.main_site_host

    config.action_controller.default_url_options = { host: Settings.main_site_host }

    # Initially for devise emails
    config.action_mailer.default_url_options = Settings.url_defaults

    # For uploads..?
    config.action_controller.forgery_protection_origin_check = false

    # Use routes for error pages instead of the default
    # static pages in 'public'
    config.exceptions_app = self.routes

    # See lib/logger_with_domain.rb
    config.middleware.insert_before(Rails::Rack::Logger, LoggerWithDomain)
    config.middleware.delete(Rails::Rack::Logger)

    # Deprecated in Rails 7 so let's not use it
    #config.active_storage.replace_on_assign_to_many = false

    # Delayed job for background jobs
    config.active_job.queue_adapter = :delayed_job
  end
end
