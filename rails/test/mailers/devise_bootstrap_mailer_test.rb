require "test_helper"

class DeviseBootstrapMailerTest < ActionMailer::TestCase

  def setup
    @user = users(:bobby)
    @token = 'abc123'
  end

  test 'smoke test' do
    {
      confirmation_instructions: [@user, @token],
      reset_password_instructions: [@user, @token],
      unlock_instructions: [@user, @token],
      email_changed: [@user],
      password_change: [@user],

    }.each do |email_type, params|
      email = DeviseBootstrapMailer.send(email_type, *params)
      assert_emails 1 do
        email.deliver_later
      end

      assert_equal [@user.email], email.to
      assert_match /Tiddlyhost /, email.subject
      assert_match '<div class="card-header" style=', email.html_part.body.decoded
      assert_match /Tiddlyhost/, email.text_part.body.decoded
    end

    # Two of the emails have variations used when the user is changing
    # email address. Ensure they work too.
    #
    @user.update(unconfirmed_email: "somenewemail@tables.com")

    {
      confirmation_instructions: [@user, @token],
      email_changed: [@user],

    }.each do |email_type, params|
      email = DeviseBootstrapMailer.send(email_type, *params)
      assert_emails 1 do
        email.deliver_later
      end

      assert_equal [@user.email], email.to
      assert_match /Tiddlyhost /, email.subject
      assert_match '<div class="card-header" style=', email.html_part.body.decoded
      assert_match /Tiddlyhost/, email.text_part.body.decoded
    end
  end

end
