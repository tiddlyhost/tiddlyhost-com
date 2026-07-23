class RegistrationsController < Devise::RegistrationsController
  include Recaptcha::Adapters::ControllerMethods

  prepend_before_action :check_recaptcha, only: [:create]
  after_action :update_logout_everywhere_pref, only: [:update]

  def destroy
    th_log("Account #{resource.id} #{resource.email} deletion")
    super
  end

  protected

  def after_inactive_sign_up_path_for(_resource)
    '/home/after_registration'
  end

  private

  # https://github.com/heartcombo/devise/wiki/How-To:-Use-Recaptcha-with-Devise#deviseregistrationscontroller
  def check_recaptcha
    return unless Settings.recaptcha_enabled?

    # The permit_devise_params before action defined in ApplicationController didn't run yet,
    # so do this here as well so that the name and username params can be preserved when doing
    # resource_class.new(sign_up_param) below.
    devise_parameter_sanitizer.permit(:sign_up, keys: [:name, :username])

    ok = verify_recaptcha(action: 'signup', minimum_score: dotty_gmail?(sign_up_params['email']) ? 0.29 : 0)
    log_recaptcha_detail(sign_up_params['email'], ok, recaptcha_reply)
    return if ok

    # Help a real user being rejected with "error-codes"=>["browser-error"]
    return if Settings.secrets(:recaptcha, :email_allow_list)&.include?(sign_up_params['email'])

    self.resource = resource_class.new(sign_up_params)
    resource.validate # Look for any other validation errors besides reCAPTCHA
    set_minimum_password_length

    respond_with_navigational(resource) do
      flash.discard(:recaptcha_error) # We need to discard flash to avoid showing it on the next page reload
      render :new
    end
  end

  def dotty_gmail?(email)
    local, domain = email.to_s.split('@', 2)
    domain&.downcase == 'gmail.com' && local.count('.') >= 3
  end

  def log_recaptcha_detail(email, ok, detail)
    th_log "Recaptcha #{ok ? 'pass' : 'fail'} for '#{email}'#{" #{detail.inspect}" if detail}"
  end

  # Handled separately from Devise's update because it's stored in the
  # preferences JSON column, not a regular attribute.
  def update_logout_everywhere_pref
    return unless params[:user]

    value = params[:user][:logout_everywhere] == '1' ? 'on' : 'off'
    current_user.logout_everywhere_pref = value
  end
end
