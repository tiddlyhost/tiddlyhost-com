# frozen_string_literal: true

class PayBootstrapUserMailer < Pay::UserMailer

  layout 'bootstrap-mailer'
  default template_path: 'pay/user_mailer'

  #
  # The methods are from here:
  # https://github.com/pay-rails/pay/blob/v6.3.1/app/mailers/pay/user_mailer.rb
  # but with make_bootstrap_mail instead of mail.
  #
  # This might need updating in future if there are changes to that file.
  # This is not very DRY but I can't think of a nice way to do it.
  #
  def receipt
    if params[:pay_charge].respond_to? :receipt
      attachments[params[:pay_charge].filename] = params[:pay_charge].receipt
    end

    @email_title = "Payment receipt"
    make_bootstrap_mail tweak_subject mail_arguments
  end

  def refund
    @email_title = "Refund processed"
    make_bootstrap_mail tweak_subject mail_arguments
  end

  def subscription_renewing
    @email_title = "Subscription renewal"
    make_bootstrap_mail tweak_subject mail_arguments
  end

  def payment_action_required
    @email_title = "Payment confirmation required"
    make_bootstrap_mail tweak_subject mail_arguments
  end

  def subscription_trial_will_end
    @email_title = "Subscription trial ending soon"
    make_bootstrap_mail tweak_subject mail_arguments
  end

  def subscription_trial_ended
    @email_title = "Subscription trial ended"
    make_bootstrap_mail tweak_subject mail_arguments
  end

  def payment_failed
    @email_title = "Payment declined"
    make_bootstrap_mail tweak_subject mail_arguments
  end

  private

  def tweak_subject(orig)
    new_subject = "Tiddlyhost #{@email_title.downcase}"
    orig.merge(subject: new_subject)
  end

end
