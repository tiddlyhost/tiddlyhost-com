#
# To preview emails:
# - http://tiddlyhost.local:3333/rails/mailers/ or https://tiddlyhost.local/rails/mailers/
#
class DeviseBootstrapMailerPreview < ActionMailer::Preview

  def initialize(params = {})
    @user = User.first
    @token = 'abc123'
    super
  end

  def confirmation_instructions
    DeviseBootstrapMailer.confirmation_instructions(@user, @token)
  end

  def confirmation_instructions_on_email_change
    stub_unconfirmed_email
    DeviseBootstrapMailer.confirmation_instructions(@user, @token)
  end

  def reset_password_instructions
    DeviseBootstrapMailer.reset_password_instructions(@user, @token)
  end

  # May be unused also since I'm not sure if account locking is enabled
  def unlock_instructions
    DeviseBootstrapMailer.unlock_instructions(@user, @token)
  end

  # Pretty sure this is unused..
  def email_changed
    DeviseBootstrapMailer.email_changed(@user)
  end

  # Pretty sure this is unused..
  def email_change_in_progress
    stub_unconfirmed_email
    DeviseBootstrapMailer.email_changed(@user)
  end

  # Pretty sure this is unused..
  def password_change
    DeviseBootstrapMailer.password_change(@user)
  end

  private

  # Beware this is enough to impact the email content but might not
  # set the "to" address realistically in the preview
  #
  def stub_unconfirmed_email
    def @user.unconfirmed_email
      'newemail@example.com'
    end
  end

end
