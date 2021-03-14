
class TiddlyspotController < ApplicationController
  layout 'tiddlyspot'

  before_action :find_site, only: [:serve, :download]

  def home
  end

  def serve
    # Todo
  end

  def options
    head 404
  end

  def favicon
    send_favicon('favicon-tiddlyspot.ico')
  end

  def download
    # Todo
  end

  private

  def find_site
    # Todo
  end

  def redirect_www_to
    Settings.tiddlyspot_url_defaults
  end

end
