
class TiddlywikiController < ApplicationController
  layout false

  before_action :find_site
  skip_before_action :verify_authenticity_token, only: :save

  def serve
    return not_found unless site_visible?

    # Don't waste time on head requests
    return render html: '' if request.head?

    # Don't count your own views
    @site.increment!(:view_count) unless user_owns_site?

    render html: @site.tiddlywiki_file.download.html_safe
  end

  def download
    return not_found unless site_downloadable?
    send_data @site.tiddlywiki_file.download,
      type: 'text/html; charset=utf-8', filename: "#{@site.name}.html"
  end

  def save
    begin
      if site_saveable?
        @site.tiddlywiki_file.attach(params[:userfile])
        render plain: "0 - OK\n"
      else
        # Give a 200 status no matter what so the user sees the message in a browser alert
        render plain: "If this is your site please log in at\n#{main_site_url} and try again.\n"
      end
    rescue => e
      # Todo: Should probably give a generic "Save failed!" message, and log the real problem
      render plain: "#{e.class.name} - #{e.message}\n"
    end
  end

  private

  def not_found
    render :not_found, status: 404, layout: 'simple'
  end

  def site_visible?
    @site.present? && (@site.is_public? || user_owns_site?)
  end

  def site_downloadable?
    site_visible?
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
