#
# Read settings from config/settings.yml and config/settings_local.yml
#
class Settings
  SETTINGS = begin
    # Since we might run this before Rails has started
    rails_root = '/opt/app'
    rails_env = ENV['RAILS_ENV'] || 'development'

    read_settings = ->(settings_file) do
      file_name = "#{rails_root}/config/#{settings_file}.yml"
      YAML.load(ERB.new(File.read(file_name)).result) || {}
    end

    settings = read_settings["settings"]
    settings_local = read_settings["settings_local"]

    settings['defaults'].merge(settings[rails_env]).merge(settings_local)
  end

  def self.method_missing(method)
    SETTINGS[method.to_s]
  end

  def self.secrets(*dig_args)
    Rails.application.credentials.dig(*dig_args)
  end

  def self.main_site_host
    Settings.url_defaults[:host]
  end

  def self.main_site_url
    ActionDispatch::Http::URL.full_url_for(Settings.url_defaults)
  end

  def self.tiddlyspot_enabled?
    Rails.env.test? || Settings.secrets(:dreamobjects).present?
  end

  def self.tiddlyspot_url_defaults
    Settings.url_defaults.merge(host: Settings.tiddlyspot_host, protocol: 'http')
  end

  def self.tiddlyspot_url
    ActionDispatch::Http::URL.full_url_for(tiddlyspot_url_defaults)
  end

  def self.subdomain_site_url(site_name)
    ActionDispatch::Http::URL.full_url_for(Settings.url_defaults.merge(subdomain: site_name))
  end

  def self.tiddlyspot_site_url(site_name)
    ActionDispatch::Http::URL.full_url_for(tiddlyspot_url_defaults.merge(subdomain: site_name))
  end

  def self.force_ssl
    self.url_defaults[:protocol] == 'https'
  end

end
