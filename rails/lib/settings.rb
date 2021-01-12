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

  def self.main_site_url
    #
    # Fixme, why can't I use this or something like it?
    # For some reason it includes the current request path
    #full_url_for(Settings.url_defaults)
    #
    if Settings.url_defaults[:port]
      "%<protocol>s://%<host>s:%<port>s/" % Settings.url_defaults
    else
      "%<protocol>s://%<host>s/" % Settings.url_defaults
    end
  end

  def self.tw_site_url(site_name)
    #
    # Fixme, need a better home for this
    #
    if Settings.url_defaults[:port]
      "%<protocol>s://%<site_name>s.%<host>s:%<port>s/" % Settings.url_defaults.merge(site_name: site_name)
    else
      "%<protocol>s://%<site_name>s.%<host>s/" % Settings.url_defaults.merge(site_name: site_name)
    end
  end

end
