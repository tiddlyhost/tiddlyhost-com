# frozen_string_literal: true

class SessionsController < Devise::SessionsController
  before_action :configure_sign_in_params, only: [:create]

  private

  def configure_sign_in_params
    devise_parameter_sanitizer.permit(:sign_in, keys: [:redir_to_site])
  end

  def after_sign_in_path_for(resource)
    # If the user was trying to view their private site then redirect
    # to that site after login succeeds
    return @site.url if request.post? && params[:user] &&
      (@site_redir = params[:user][:site_redir]) &&
      (@site = Site.find_by_name(@site_redir)) &&
      @site.user == current_user

    super
  end

end
