
class RegistrationsController < Devise::RegistrationsController
  include Recaptcha::Adapters::ControllerMethods

  prepend_before_action :check_recaptcha, only: [:create]

  def destroy
    th_log("Account #{resource.id} #{resource.email} deletion")
    super
  end

  protected

  def after_inactive_sign_up_path_for(resource)
    '/home/after_registration'
  end

  private

  # https://github.com/heartcombo/devise/wiki/How-To:-Use-Recaptcha-with-Devise#deviseregistrationscontroller
  def check_recaptcha
    ok = verify_recaptcha(action: 'signup')
    log_recaptch_detail(sign_up_params['email'].strip, ok, recaptcha_reply)
    return if ok

    # (Not sure how important this part is, but it's from the example.)
    self.resource = resource_class.new(sign_up_params)
    resource.validate # Look for any other validation errors besides reCAPTCHA
    set_minimum_password_length

    respond_with_navigational(resource) do
      flash.discard(:recaptcha_error) # We need to discard flash to avoid showing it on the next page reload
      render :new
    end
  end

  def log_recaptch_detail(email, ok, detail)
    th_log "Recaptcha #{ok ? "pass" : "fail"} for #{email}#{" #{detail.inspect}" if detail}"
  end

end
