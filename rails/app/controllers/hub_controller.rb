class HubController < ApplicationController
  PER_PAGE = 18

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

  include SortAndFilterLinkHelper

  FILTER_PARAMS = {
    q: {
      # Searching is handled in HubQuery
    }
  }.freeze

  # We don't do asc/desc sorting for the hub
  SORT_OPTIONS = {
    v: { title: 'view count', field: 'view_count DESC' },
    u: { title: 'recently updated', field: 'blob_created_at DESC NULLS LAST' },
    c: { title: 'recently created', field: 'created_at DESC NULLS LAST' },
    a: { title: 'name a-z', field: 'name ASC' },
    z: { title: 'name z-a', field: 'name DESC' },
    r: { title: 'random', field: 'rand_sort' },
  }.freeze

  DEFAULT_SORT = :v

  private

  def render_hub
    # Show a few popular tags in the tab bar.
    # (It's not the best UX for tag based site discovery, but good enough for now.)
    @tag_tabs = HubQuery.most_used_tags.first(Settings.hub_tag_tab_count)

    # If there's a particular tag selected, show that in the tab bar also
    @tag_tabs = @tag_tabs.prepend(@tag) if @tag.present? && !@tag_tabs.include?(@tag)

    # See lib/hub_query
    @sites = HubQuery.paginated_sites(
      page: params[:page],
      per_page: PER_PAGE,
      sort_by: sort_opt[:field],
      tag: @tag,
      user: @user,
      search: search_text)

    # Render
    render action: :index
  end

end
