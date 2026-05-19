class SsoController < ApplicationController
  before_action :authenticate_user!, only: [:authorize]

  # GET /sso/authorize?domain=customdomain.com&return_to=/
  # Runs on tiddlyhost.com. Generates a signed token and redirects to the custom domain callback.
  def authorize
    domain = params[:domain]
    return_to = safe_return_to(params[:return_to])

    custom_domain = CustomDomain.fully_active.find_by(domain: domain)
    unless custom_domain
      render plain: "Domain not found", status: :not_found
      return
    end

    unless custom_domain.site.user == current_user
      render plain: "Forbidden", status: :forbidden
      return
    end

    token = SsoToken.generate(user_id: current_user.id, domain: domain, return_to: return_to)
    redirect_to "https://#{domain}/sso/callback?token=#{CGI.escape(token)}", allow_other_host: true
  end

  # GET /sso/callback?token=xyz
  # Runs on custom domain. Verifies token, creates session, redirects.
  def callback
    data = SsoToken.verify(params[:token], domain: request.host)
    unless data
      render plain: "Invalid or expired token", status: :forbidden
      return
    end

    user = User.find_by(id: data[:user_id])
    unless user
      render plain: "User not found", status: :forbidden
      return
    end

    sign_in(:user, user)
    redirect_to safe_return_to(data[:return_to]) || "/"
  end

  # GET /sso/init?return_to=/
  # Runs on custom domain. Redirects to tiddlyhost.com to start the SSO flow.
  def init
    return_to = safe_return_to(params[:return_to])
    redirect_to "#{Settings.main_site_url}/sso/authorize?domain=#{request.host}&return_to=#{CGI.escape(return_to)}",
      allow_other_host: true
  end

  # GET /logout
  # Runs on custom domain. Signs out the custom domain session only.
  def logout
    sign_out(current_user) if current_user
    redirect_to "/"
  end

  private

  def safe_return_to(path)
    path = path.to_s
    return "/" unless path.start_with?("/") && !path.start_with?("//")

    path
  end
end
