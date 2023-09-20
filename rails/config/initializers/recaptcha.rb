
Recaptcha.configure do |config|
  config.site_key = Settings.secrets(:recaptcha, :site_key)
  config.secret_key = Settings.secrets(:recaptcha, :secret_key)
end
