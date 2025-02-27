class TiddlyspotController < ApplicationController
  layout 'tiddlyspot'

  include SubdomainCommon

  before_action :find_site, only: [:serve, :download, :thumb_png, :save]
  before_action :redirect_maybe, only: [:serve] # Todo: consider the others
  before_action :blank_html_check, only: [:serve, :download, :thumb_png, :save]
  before_action :authenticate, only: [:serve, :download, :thumb_png], if: :auth_required?

  skip_before_action :verify_authenticity_token, only: [:save, :options]

  def home
  end

  def serve
    update_access_count_and_timestamp
    etag_header
    nginx_no_buffering_header
    render html: @site.html_content.html_safe, layout: false
  end

  def download
    update_access_count_and_timestamp
    etag_header
    nginx_no_buffering_header
    download_html_content(@site.html_content, @site.name)
  end

  def options
    head 404
  end

  def favicon
    send_favicon('favicon-tiddlyspot.ico')
  end

  def thumb_png
    return head 404 unless @site.thumbnail.present?

    send_data @site.thumbnail.download, type: 'image/png', disposition: 'inline'
  end

  def save
    begin
      if @site.passwd_ok?(upload_params[:user], upload_params[:password])
        @site.file_upload(params[:userfile])
        @site.increment_save_count
        render plain: "0 - OK\n"
      else
        render plain: "Password incorrect\n"
      end
    rescue StandardError => e
      # Todo: Should probably give a generic "Save failed!" message, and log the real problem
      render plain: "#{e.class.name} - #{e.message}\n"
    end
  end

  private

  def update_access_count_and_timestamp
    @site.touch_accessed_at
    @site.increment_access_count
  end

  def find_site
    @site_name = request.subdomain
    @site = TspotSite.find_and_populate(@site_name, request.ip)
    render :site_not_found, status: 404 unless @site
  end

  def redirect_maybe
    redirect_to @site.redirect_to if @site.redirect_to.present?
  end

  # When a site with a missing index.html gets populated, the html_content becomes an
  # empty string. Treat that as a 404. (At some point I'll delete sites like this.)
  # Do this after redirect_maybe to avoid doing an unnecessary blob fetch in find_site.
  def blank_html_check
    render :site_not_found, status: 404 unless @site.html_content.present?
  end

  def auth_required?
    @site.is_private?
  end

  def authenticate
    realm = "Authenticate to access private site '#{@site.name}'"
    @status_code = 401
    @status_message = 'Unauthorized'
    message = render_to_string 'home/error_page'
    authenticate_or_request_with_http_basic(realm, message) do |username, passwd|
      @site.passwd_ok?(username, passwd)
    end
  end

  def redirect_www_to
    Settings.tiddlyspot_url_defaults
  end

  def upload_params
    @_upload_params ||= begin
      key_value_strings = params[:UploadPlugin].strip.split(';').map(&:presence).compact
      key_value_strings.to_h { |kv| kv.split('=') }.with_indifferent_access
    end
  end
end
