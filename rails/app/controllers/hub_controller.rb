class HubController < ApplicationController

  def index
    @sites = Site.searchable.paginate(page: params[:page])
  end

end
