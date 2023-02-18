
require "test_helper"

class PayBootstrapUserMailerTest < ActionMailer::TestCase

  # See also test/mailers/previews/pay_bootstrap_user_mailer_preview.rb
  def setup
    @user = User.first
    @customer = @user.pay_customer_stripe
    @charge = @customer.charges.first

    # Not all emails use all these params but I'm being lazy
    @email_params = {
      pay_customer: @customer,
      pay_charge: @charge,
      date: Date.tomorrow,
      payment_indent_id: @charge.payment_intent_id,
    }
  end

  test 'smoke test' do
    %i[
      receipt
      refund
      subscription_renewing
      payment_action_required
      subscription_trial_will_end
      subscription_trial_ended
      payment_failed

    ].each do |email_type|
      email = Pay.mailer.with(@email_params).send(email_type)

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
