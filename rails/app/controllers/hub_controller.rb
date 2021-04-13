class HubController < ApplicationController
  PER_PAGE = 15

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

  # s = sort
  # q = search (query)
  FILTER_PARAMS = %i[
    s
    q
  ]

  private

  def render_hub
    @sort_options = {
      'v' => {
        name: 'view count',
        field: 'view_count DESC',
      },
      'u' => {
        name: 'recently updated',
        field: 'blob_created_at DESC NULLS LAST',
      },
      'n' => {
        name: 'name',
        field: 'name ASC',
      },
    }
    @sort_by = @sort_options[params[:s]] || @sort_options['v']

    @search = params[:q]

    # Show four popular tags in the tab bar.
    # (It's not the best UX for tag based site discovery, but good enough for now.)
    @tag_tabs = HubQuery.tags_for_searchable_sites.limit(4).pluck(:name)

    # If there's a particular tag selected, show that in the tab bar also
    @tag_tabs = @tag_tabs.prepend(@tag) if @tag.present? && !@tag_tabs.include?(@tag)

    # See lib/hub_query
    @sites = HubQuery.paginated_sites(
      page: params[:page],
      per_page: PER_PAGE,
      sort_by: @sort_by[:field],
      tag: @tag,
      user: @user,
      search: @search)

    # Render
    render action: :index
  end

end
