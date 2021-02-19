
class ApplicationController < ActionController::Base
  before_action :redirect_www_requests
  before_action :permit_devise_params, if: :devise_controller?

  protected

  def main_site_url
    Settings.main_site_url
  end

  def default_url_options
    Rails.application.routes.default_url_options = Settings.url_defaults
  end

  def redirect_www_requests
    redirect_to(Settings.url_defaults, status: 301) if request.subdomain == 'www'
  end

  def permit_devise_params
    devise_parameter_sanitizer.permit(:sign_up, keys: [:name])
    devise_parameter_sanitizer.permit(:account_update, keys: [:name])
  end

  def require_admin_user!
    # Todo: A nicer 403 response
    raise "Unauthorized!" unless current_user && current_user.is_admin?
  end

  # Used for serving custom favicons
  def local_asset_path(asset_name)
    manifest = Rails.application.assets_manifest
    if asset_file = manifest.assets[asset_name]
      # For production with compiled assets
      File.join(manifest.directory, asset_file)
    else
      # For development
      Rails.application.assets[asset_name].filename
    end
  end

end
