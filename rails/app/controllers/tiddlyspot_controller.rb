
class TiddlyspotController < ApplicationController
  layout 'tiddlyspot'

  before_action :find_site, only: [:serve, :download, :save]
  before_action :authenticate, only: [:serve, :download], if: :auth_required?

  skip_before_action :verify_authenticity_token, only: [:save, :options]

  def home
  end

  def serve
    update_access_count_and_timestamp
    render html: @site.html_content.html_safe, layout: false
  end

  def download
    update_access_count_and_timestamp
    download_html_content(@site.html_content, @site.name)
  end

  def options
    head 404
  end

  def favicon
    send_favicon('favicon-tiddlyspot.ico')
  end

  def save
    begin
      if @site.passwd_ok?(upload_params[:user], upload_params[:password])
        @site.tiddlywiki_file.attach(params[:userfile])
        @site.increment_save_count
        render plain: "0 - OK\n"
      else
        render plain: "Password incorrect\n"
      end
    rescue => e
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
    site_name = request.subdomain
    @site = TspotSite.find_or_create(site_name)
    if !@site.exists?
      # Let's record accesses to phantom sites
      update_access_count_and_timestamp
      return render :site_not_found, status: 404
    end
  end

  def auth_required?
    @site.is_private?
  end

  def authenticate
    realm = "Authenticate to access private site '#{@site.name}'"
    @status_code = 401
    @status_message = "Unauthorized"
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
      Hash[ key_value_strings.map{ |kv| kv.split('=') } ].with_indifferent_access
    end
  end

end
