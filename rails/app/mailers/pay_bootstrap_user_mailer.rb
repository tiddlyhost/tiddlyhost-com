
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

    make_bootstrap_mail mail_arguments
  end

  def refund
    make_bootstrap_mail mail_arguments
  end

  def subscription_renewing
    make_bootstrap_mail mail_arguments
  end

  def payment_action_required
    make_bootstrap_mail mail_arguments
  end

  def subscription_trial_will_end
    make_bootstrap_mail mail_arguments
  end

  def subscription_trial_ended
    make_bootstrap_mail mail_arguments
  end

  def payment_failed
    make_bootstrap_mail mail_arguments
  end

end
