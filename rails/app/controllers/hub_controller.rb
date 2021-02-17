class HubController < ApplicationController
  before_action :prepare_sites

  # TODO: Searching and sorting

  def index
  end

  def twplugins
  end

  def twdocs
  end

  private

  def prepare_sites
    @sites = Site.searchable
    @hub_tags = Settings.hub_tags

    if @hub_tags.keys.include?(action_name)
      @title = @hub_tags[action_name][:title]
      @tag = @hub_tags[action_name][:tag]
      @sites = @sites.tagged_with(@tag)
    else
      @title = "Tiddlyhost Hub"
    end

    @sites = @sites.paginate(page: params[:page])

    render action: :index
  end

end
