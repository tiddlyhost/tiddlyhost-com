
class TiddlywikiController < ApplicationController
  layout false

  before_action :find_site
  skip_before_action :verify_authenticity_token, only: [:save, :options]

  def serve
    return not_found unless site_visible?

    # Don't waste time on head requests
    return render html: '' if request.head?

    update_view_count_and_access_timestamp

    render html: @site.html_content.html_safe
  end

  # TiddlyWiki does an OPTIONS request to query the server capabilities
  # and check if the put saver could be used. Just return a 404 with no body.
  def options
    head 404
  end

  def favicon
    return not_found unless site_visible?

    send_file local_asset_path(@site.favicon_asset_name),
      type: 'image/vnd.microsoft.icon', disposition: 'inline'
  end

  def download
    return not_found unless site_downloadable?

    # Downloads count as a view
    update_view_count_and_access_timestamp

    send_data @site.html_content,
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

  def update_view_count_and_access_timestamp
    # Don't count admin user clicks
    return if user_is_admin?

    # Don't count views by site owner
    @site.increment_view_count unless user_owns_site?

    # ..but always touch the timestamp
    @site.touch_accessed_at
  end

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
