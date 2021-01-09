
class ApplicationController < ActionController::Base
  before_action :redirect_www_requests
  before_action :permit_devise_params, if: :devise_controller?

  protected

  def redirect_www_requests
    redirect_to(Settings.home_url, status: 301) if request.subdomain == 'www'
  end

  def permit_devise_params
    devise_parameter_sanitizer.permit(:sign_up, keys: [:name])
    devise_parameter_sanitizer.permit(:account_update, keys: [:name])
  end

end
