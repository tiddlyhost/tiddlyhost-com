class HubController < ApplicationController

  def index
    render_hub
  end

  def tag
    @tag = params[:tag]
    render_hub
  end

  def user
    if params[:username].present? && user = User.find_by_username(params[:username])
      @user = user
      render_hub
    else
      # TODO: 404 page here maybe
      redirect_to '/hub'
    end
  end

  private

  def render_hub
    # Prepare sort options
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

    # Prepare search
    @search = params[:search]

    # Prepare tag tabs. Show four popular tags in the tab bar.
    # (It's not the best UX for tag based site discovery, but good enough for now.)
    @tag_tabs = Site.tags_for_searchable_sites.limit(4).pluck(:name)

    # If there's a particular tag selected, show that in the tab bar also
    @tag_tabs = @tag_tabs.prepend(@tag) if @tag.present? && !@tag_tabs.include?(@tag)

    # Start with all 'searchable' sites
    @sites = Site.searchable

    # Exclude brand new sites since they're probably just a blank empty file
    @sites = @sites.updated_at_least_once

    # Apply sorting
    @sites = @sites.order(@sort_by[:field])

    # Apply tag filtering
    @sites = @sites.tagged_with(@tag) if @tag.present?

    # Apply user filtering
    @sites = @sites.owned_by(@user) if @user.present?

    # Apply search filtering
    @sites = @sites.search_for(@search) if @search.present?

    # Paginate
    @sites = @sites.paginate(page: params[:page])

    # Render
    render action: :index
  end

end
