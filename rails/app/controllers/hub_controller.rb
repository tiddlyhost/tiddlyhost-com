class HubController < ApplicationController
  before_action :prepare_sorting,
    :prepare_searching,
    :prepare_tags,
    :prepare_sites_and_render

  def index
  end

  def tag
  end

  # (Unused currently)
  def twplugins
  end

  # (Unused currently)
  def twdocs
  end

  private

  def prepare_sites_and_render
    @sites = Site.searchable.order(@sort_by[:field])
    @sites = @sites.tagged_with(@tag) if @tag.present?
    @sites = @sites.search_for(@search) if @search.present?
    @sites = @sites.paginate(page: params[:page])

    render action: :index
  end

  def prepare_tags
    @hub_tags = Settings.hub_tags
    @tag_tabs = Site.tags_for_searchable_sites.limit(4).pluck(:name)

    # (Unused currently since there are no hub_tags)
    if @hub_tags.keys.include?(action_name)
      tag_info = @hub_tags[action_name]
      @tag = tag_info[:tag]
      @title = tag_info[:title]
      @tag_description = tag_info[:description]

    elsif params[:tag]
      @tag = params[:tag]
      # Beware that @tag is html unsafe
      @tag_tabs = @tag_tabs.prepend(@tag).uniq
      @tag_description = "Searchable sites tagged with '#{@tag}'."

    else
      @title = "Tiddlyhost Hub"
      @tag_description = "If you mark your site as 'Searchable' it will be listed here."
    end
  end

  def prepare_searching
    @search = params[:search]
  end

  def prepare_sorting
    @sort_options = {
      'views' => {
        name: 'view count',
        field: 'view_count desc',
      },
      'name' => {
        name: 'name',
        field: 'name asc',
      },
    }

    @sort_by = @sort_options[params[:sort]] || @sort_options['views']
  end

end
