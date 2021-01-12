class HomeController < ApplicationController
  before_action :authenticate_user!, except: [:index, :todo, :after_registration, :serve_tiddlywiki, :save_tiddlywiki]

  before_action :find_site, only: [:serve_tiddlywiki, :save_tiddlywiki]

  skip_before_action :verify_authenticity_token, only: :save_tiddlywiki

  def index
    if user_signed_in?
      redirect_to sites_path
    end
  end

  def serve_tiddlywiki
    if @site.is_public? || @site.user == current_user
      render html: @site.tiddlywiki_file.download.html_safe, layout: nil
    else
      render :not_found, status: 404
    end
  end

  def save_tiddlywiki
    begin
      if user_signed_in? && @site.user == current_user
        @site.tiddlywiki_file.attach(params[:userfile])
        render plain: "0 - OK\n", layout: false
      else
        render plain: "If this is your site please log in at #{main_site_url} and try again.\n", layout: false
      end
    rescue => e
      render plain: "#{e.class.name} - #{e.message}"
    end
  end

  def after_registration
    render template: 'devise/registrations/after_registration'
  end

  private

  def find_site
    site_name = request.subdomain
    @site = Site.find_by_name(site_name)
  end

end
