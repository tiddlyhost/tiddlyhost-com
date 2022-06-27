#
# See also test/mailers/previews/devise_bootstrap_mailer_preview
# Based on https://github.com/bootstrap-email/bootstrap-email/issues/41
#
class DeviseBootstrapMailer < Devise::Mailer

  layout 'bootstrap-mailer'
  default template_path: 'devise/mailer'

  def devise_mail(record, action, opts = {}, &block)
    initialize_from_record(record)

    @email_title = email_title_for(action)

    # Use bootstrap mail
    make_bootstrap_mail(headers_for(action, opts.merge(to: record.pretty_email)), &block)
  end

  private

  # See docker/bundle/ruby/3.1.0/gems/devise-4.8.1/lib/devise/mailers/helpers.rb
  # (IIUC the more correct way to change the email subject wording would be to
  # create an I18n locale file but let's save that for another day.)

  # Save the method from the base class so we can use it below
  alias_method :orig_subject_for, :subject_for

  def email_title_for(action)
    orig_subject_for(action).
      # Tweak the defaults a little
      sub(/Changed$/i, "change notification").
      sub(/^Confirmation/i, "Email confirmation").
      sub(/^Reset password/i, "Password reset").
      sub(/instructions$/i, "")
  end

  def subject_for(action)
    "Tiddlyhost #{email_title_for(action).downcase}"
  end

end
