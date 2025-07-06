class ApplicationController < ActionController::Base
  before_action :redirect_www_requests
  before_action :permit_devise_params, if: :devise_controller?

  protected

  def send_favicon(favicon_asset)
    send_file(local_asset_path(favicon_asset),
      type: 'image/vnd.microsoft.icon', disposition: 'inline')
  end

  def download_html_content(html_content, file_name)
    send_data html_content,
      type: 'text/html; charset=utf-8', filename: "#{file_name}.html"
  end

  def download_js_content(js_content, file_name)
    # For some reason using text/javascript here makes rails give a CORS
    # error. Use text/plain instead which should work just as well.
    send_data js_content,
      type: 'text/plain; charset=utf-8', filename: file_name
  end

  def main_site_url
    Settings.main_site_url
  end

  def default_url_options
    Rails.application.routes.default_url_options = Settings.url_defaults
  end

  def redirect_www_to
    Settings.url_defaults
  end

  def redirect_www_requests
    redirect_to(redirect_www_to, status: 301) if request.subdomain == 'www'
  end

  def permit_devise_params
    devise_parameter_sanitizer.permit(:sign_up, keys: [:name, :username])
    devise_parameter_sanitizer.permit(:account_update, keys: [:name, :username, :use_gravatar, :use_libravatar])
  end

  def user_is_admin?
    feature_enabled?(:admin)
  end
  helper_method :user_is_admin?

  def feature_enabled?(feature_name)
    Settings.feature_enabled?(feature_name, current_user)
  end
  helper_method :feature_enabled?

  def require_admin_user!
    require_feature_enabled!(:admin)
  end

  def require_condition!(condition)
    return if condition

    # 403 would be more accurate but let's pretend it's a 404
    @status_code, @status_message = 404, 'Not Found'
    render 'home/error_page', status: @status_code, layout: 'simple'
  end

  def require_feature_enabled!(feature_name)
    require_condition!(feature_enabled?(feature_name))
  end

  # Used for serving custom favicons
  def local_asset_path(asset_name)
    manifest = Rails.application.assets_manifest
    if (asset_file = manifest.assets[asset_name])
      # For production with compiled assets
      File.join(manifest.directory, asset_file)
    else
      # For development
      Rails.application.assets[asset_name].filename
    end
  end

  def th_log(msg)
    ThostLogger.thost_logger.info(msg, request)
  end

  def navbar_prod
    'navbar-prod' if request.domain =~ /(tiddlyspot|tiddlyhost)\.com$/
  end
  helper_method :navbar_prod
end
