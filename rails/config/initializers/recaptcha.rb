# frozen_string_literal: true

Recaptcha.configure do |config|
  if Rails.env.test?
    config.site_key = 'foo'
    config.secret_key = 'bar'
  else
    config.site_key = Settings.secrets(:recaptcha, :site_key)
    config.secret_key = Settings.secrets(:recaptcha, :secret_key)
  end
end
