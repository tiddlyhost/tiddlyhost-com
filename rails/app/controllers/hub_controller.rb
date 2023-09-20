class HubController < ApplicationController
  PER_PAGE = 18

  before_action :set_show_templates
  before_action :set_kind_filter

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
    # The hub filtering logic is done manually not by SortAndFilterLinkHelper
    # so that's why these are empty. We just need the keys to exist so the link
    # helpers can see them.
    q: {}, # text search
    t: {}, # template filter
    k: {'tw'=>'TiddlyWiki (any)'}.merge(SiteCommon::KINDS).to_a.map{|k, v| [k.to_sym, {title: v}]}.to_h
  }.freeze

  # We don't do asc/desc sorting for the hub
  SORT_OPTIONS = {
    v: { title: 'view count', field: 'view_count DESC' },
    cl: { title: 'clone count', field: 'clone_count DESC' },
    u: { title: 'recently updated', field: 'blob_created_at DESC NULLS LAST' },
    c: { title: 'recently created', field: 'created_at DESC NULLS LAST' },
    a: { title: 'name a-z', field: 'name ASC' },
    z: { title: 'name z-a', field: 'name DESC' },
    r: { title: 'random', field: 'rand_sort' },
  }.freeze

  private

  def render_hub
    # Show a few popular tags in the tab bar.
    # (It's not the best UX for tag based site discovery, but good enough for now.)
    @tag_tabs = HubQuery.most_used_tags(for_templates: @show_templates).first(Settings.hub_tag_tab_count)

    # If there's a particular tag selected, show that in the tab bar also
    @tag_tabs = @tag_tabs.prepend(@tag) if @tag.present? && !@tag_tabs.include?(@tag)

    # See lib/hub_query
    @sites = HubQuery.paginated_sites(
      page: params[:page],
      per_page: PER_PAGE,
      sort_by: sort_opt[:field],
      templates_only: @show_templates,
      kind: @kind_filter,
      tag: @tag,
      user: @user,
      search: search_text)

    # Render
    render action: :index
  end

  def set_show_templates
    @show_templates = params[:t] == '1'
  end

  def set_kind_filter
    params.delete(:k) unless params[:k].in?(filter_params[:k].keys.map(&:to_s))
    @kind_filter = params[:k]
  end

  def default_sort
    @show_templates ? :cl : :v
  end

end
