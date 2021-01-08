class ApplicationController < ActionController::Base
  before_action :redirect_www_requests

  def redirect_www_requests
    redirect_to(Settings.home_url, status: 301) if request.subdomain == 'www'
  end
end
