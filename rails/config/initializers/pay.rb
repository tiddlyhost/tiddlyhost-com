# frozen_string_literal: true

# Avoid an error due to Mail::Address not existing yet (??)
require 'mail'

Pay.setup do |config|
  # For use in receipt/refund/renewal emails
  config.business_name = 'https://tiddlyhost.com/'
  config.business_address = ''
  config.application_name = 'Tiddlyhost'
  config.support_email = Settings.stripe_support_email

  config.mailer = 'PayBootstrapUserMailer'
end
