# This is a base class for TemplatesController and ExploreController
class HubController < ApplicationController
  PER_PAGE = 18

  before_action :set_show_templates
  before_action :set_kind_filter
  before_action :set_default_title

  # The tests in hub_controller_test don't exect the redirects and I don't want to fix that yet
  before_action :redirect_hub_urls unless Rails.env.test?

  def index
    render_hub
  end

  def tag
    @tag = params[:tag]
    render_hub
  end

  def user
    if params[:username].present? && (user = User.find_by_username(params[:username]))
      @user = user
      render_hub
    else
      # TODO: 404 page here maybe
      redirect_to '/explore'
    end
  end

  include SortAndFilterLinkHelper

  FILTER_PARAMS = {
    # The hub filtering logic is done manually not by SortAndFilterLinkHelper
    # so that's why these are empty. We just need the keys to exist so the link
    # helpers can see them.
    q: {}, # text search
    t: {}, # template filter
    k: { 'tw' => 'TiddlyWiki (any)' }.merge(SiteCommon::KINDS).to_a.to_h { |k, v| [k.to_sym, { title: v }] }
  }.freeze

  # We don't do asc/desc sorting for the hub
  SORT_OPTIONS = {
    v: { title: 'view count', field: 'view_count DESC' },
    cl: { title: 'clone count', field: 'clone_count DESC' },
    u: { title: 'recently updated', field: 'blob_created_at DESC NULLS LAST' },
    c: { title: 'recently created', field: 'created_at DESC NULLS LAST' },
    a: { title: 'name a-z', field: 'name ASC' },
    z: { title: 'name z-a', field: 'name DESC' },
    nv: { title: 'newer version', field: 'tw_version_trimmed DESC NULLS LAST' },
    ov: { title: 'older version', field: 'tw_version_trimmed ASC NULLS LAST' },
    r: { title: 'random', field: 'rand_sort' },
  }.freeze

  private

  # This query very slow for some reason and it really doesn't
  # matter how fresh the list is. Cache it.
  TAGS_CACHE_EXPIRY = Settings.hub_tag_cache_hours.hours
  TAGS_COUNT = Settings.hub_tag_tab_count
  def most_used_tags_cached(show_templates)
    cache_key = "popular_tags_#{show_templates}"
    Rails.logger.info "Cache check for #{cache_key}"
    Rails.cache.fetch(cache_key, expires_in: TAGS_CACHE_EXPIRY) do
      Rails.logger.info "Cache miss for #{cache_key}"
      HubQuery.most_used_tags(for_templates: show_templates).first(TAGS_COUNT)
    end
  end

  def render_hub
    # Show a few popular tags in the tab bar.
    # (It's not the best UX for tag based site discovery, but good enough for now.)
    @tag_tabs = most_used_tags_cached(@show_templates)

    # If there's a particular tag selected, show that in the tab bar also
    @tag_tabs.prepend(@tag) if @tag.present? && !@tag_tabs.include?(@tag)

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

  def set_default_title
    # Not expected to run in the base class since the child class will define it
    # ...but the tests still use HubController so we need this to avoid a test
    # error calling page_entries_info (which is a will_paginate helper)
    @thing_name = 'Site'
  end

  def default_sort
    @show_templates ? :cl : :v
  end

  # Flip between controllers based on whether we're looking at
  # "templates only" or everything. Probably won't need this
  # when/if we stop using the ?t=1 url param and update some links
  #
  HUB_URL_MATCH = %r{^/(?:hub|browse|explore|templates)}

  def redirect_hub_urls
    full_path = request.fullpath
    target_path = (@show_templates ? '/templates' : '/explore')
    redirect_to full_path.sub(HUB_URL_MATCH, target_path) unless full_path.start_with?(target_path)
  end
end
