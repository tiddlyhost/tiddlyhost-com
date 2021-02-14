class HomeController < ApplicationController
  before_action :find_site, only: [:serve_tiddlywiki, :save_tiddlywiki]
  skip_before_action :verify_authenticity_token, only: :save_tiddlywiki

  def index
    if user_signed_in?
      redirect_to sites_path
    end
  end

  def serve_tiddlywiki
    if site_visible?
      render html: @site.tiddlywiki_file.download.html_safe, layout: nil
    else
      render :not_found, status: 404, layout: 'simple'
    end
  end

  def save_tiddlywiki
    begin
      if site_saveable?
        @site.tiddlywiki_file.attach(params[:userfile])
        render plain: "0 - OK\n", layout: false
      else
        # Give a 200 status no matter what so the user sees the message in a browser alert
        render plain: "If this is your site please log in at #{main_site_url} and try again.\n", layout: false
      end
    rescue => e
      # Todo: Should probably give a generic "Save failed!" message, and log the real problem
      render plain: "#{e.class.name} - #{e.message}", layout: false
    end
  end

  def after_registration
    render template: 'devise/registrations/after_registration'
  end

  def donate
  end

  private

  def site_visible?
    @site.present? && (@site.is_public? || user_owns_site?)
  end

  def site_saveable?
    @site.present? && user_owns_site?
  end

  def user_owns_site?
    user_signed_in? && current_user == @site.user
  end

  def find_site
    site_name = request.subdomain
    @site = Site.find_by_name(site_name)
  end

end
