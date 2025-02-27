module SubdomainCommon
  extend ActiveSupport::Concern

  included do
    after_action :manage_iframe_header, only: :serve
  end

  def manage_iframe_header
    response.headers.except!('X-Frame-Options') if @site&.allow_in_iframe?
  end

  def etag_header
    response.set_header 'ETag', @site.tw_etag
  end

  # This should instruct nginx to stream the large response
  # directly to the client rather than buffer it
  def nginx_no_buffering_header
    response.set_header 'X-Accel-Buffering', 'no'
  end
end
