class HubController < ApplicationController
  before_action :prepare_sites

  # TODO: Searching and sorting

  def index
  end

  def twplugins
  end

  def twdocs
  end

  def tag
  end

  private

  def prepare_sites
    @hub_tags = Settings.hub_tags

    if @hub_tags.keys.include?(action_name)
      tag_info = @hub_tags[action_name]
      @tag = tag_info[:tag]
      @title = tag_info[:title]
      @tag_description = tag_info[:description]

    elsif params[:tag]
      @tag = params[:tag]
      @extra_tab = true
      # Beware these are html unsafe
      @title = "Tag '#{@tag}'"
      @tag_description = "Searchable sites tagged with '#{@tag}'."

    else
      @title = "Tiddlyhost Hub"
      @tag_description = "If you mark your site as 'Searchable' it will be listed here."
    end

    @sites = Site.searchable
    @sites = @sites.tagged_with(@tag) if @tag
    @sites = @sites.paginate(page: params[:page])

    render action: :index
  end

end
