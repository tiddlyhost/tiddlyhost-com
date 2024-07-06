# frozen_string_literal: true

#
# To preview emails:
# - http://tiddlyhost.local:3333/rails/mailers/ or https://tiddlyhost.local/rails/mailers/
#
# Todo: Figure out which of these we are really using.
#
class PayBootstrapUserMailerPreview < ActionMailer::Preview
  def initialize(params = {})
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

    super
  end

  def receipt
    do_email :receipt
  end

  def refund
    do_email :refund
  end

  def subscription_renewing
    do_email :subscription_renewing
  end

  # Fixme maybe: This doesn't work (I think) because
  # there's no controller for the pay/payments/:id route
  def payment_action_required
    do_email :payment_action_required
  end

  def subscription_trial_will_end
    do_email :subscription_trial_will_end
  end

  def subscription_trial_ended
    do_email :subscription_trial_ended
  end

  def payment_failed
    # For a failed payment this param will not be present
    @email_params[:pay_charge] = nil
    do_email :payment_failed
  end

  private

  def do_email(email_type)
    PayBootstrapUserMailer.with(@email_params).send(email_type)
  end
end
