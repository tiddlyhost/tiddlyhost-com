
module SubdomainCommon
  extend ActiveSupport::Concern

  included do
    after_action :manage_iframe_header, only: :serve
  end

  def manage_iframe_header
    response.headers.except!('X-Frame-Options') if @site.try(:allow_in_iframe?)
  end

end
