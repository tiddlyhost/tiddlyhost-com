class SitesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_site, except: [:index, :new, :create, :view_toggle, :download_all]
  before_action :set_sites, only: [:index, :download_all]
  before_action :set_empties_list, only: [:new, :create]
  before_action :set_site_to_clone, only: [:new, :create]

  include SortAndFilterLinkHelper

  include SiteHistory
  include ZipDownloadAll

  SORT_OPTIONS = {
    compressed: 'size',
    kind: 'tw_kind',
    name: 'name',
    updated: 'blob_created_at',
    version: %w[tw_kind tw_version],
    access: %w[not_searchable is_private],
    views: 'view_count',
    size: 'raw_byte_size',
    origin: 'type,id',
  }.freeze

  DEFAULT_SORT = :updated_desc

  FILTER_PARAMS = {
    # Fixme maybe: These filters could probably be moved into the db query
    access: {
      hub: { filter: ->(s) { s.select(&:hub_listed?) }, title: 'searchable' },
      public: { filter: ->(s) { s.select(&:is_public?).reject(&:hub_listed?) } },
      private: { filter: ->(s) { s.select(&:is_private?) } },
    },
    kind: SiteCommon::KINDS.to_a.to_h { |k, v| [k.to_sym,
      { filter: ->(ss) { ss.select { |s| s.tw_kind == k.to_s } }, title: v }
    ]}
  }.freeze

  NULL_ALWAYS_LAST = %w[
    version
    size
  ].freeze

  # GET /sites
  # GET /sites.json
  def index
    respond_to do |format|
      format.html do
        @list_mode = current_user.list_mode_pref
        @list_mode_next = current_user.list_mode_pref_next
      end

      format.json do
        @sites = @sites.sort_by(&:id)
      end
    end
  end

  def view_toggle
    current_user.list_mode_pref_cycle
    # Preserve filter and sort params
    redirect_to url_for(params.permit(:controller, :action, :access, :s).merge({ action: :index }))
  end

  # Any site that's been saved recently would probably already
  # have a thumbnail. This is to make it easier for users with older
  # sites.
  #
  def create_thumbnail
    @site.update_thumbnail_later unless @site.thumbnail.present?
    redirect_to sites_path
  end

  # GET /sites/1
  # GET /sites/1.json
  def show
  end

  # GET /sites/1/download
  def download
    local_core = (params[:mode] == 'local_core')
    download_html_content(@site.download_content(local_core:), @site.name)
  end

  def download_core_js
    download_js_content(@site.core_js_content, @site.core_js_name)
  end

  # GET /sites/new
  def new
    @site = Site.new(name: RandomName.generate, empty: Empty.default)
  end

  # GET /sites/1/edit
  def edit
  end

  # GET /sites/1/upload_form
  def upload_form
  end

  # POST /sites
  # POST /sites.json
  def create
    if @site_to_clone
      initial_content = @site_to_clone.file_download
    else
      empty = Empty.find(site_params_for_create[:empty_id])
      initial_content = empty.html
    end

    create_attrs = site_params_for_create.merge(WithSavedContent.attachment_params(initial_content))
    create_attrs.merge!({ cloned_from_id: @site_to_clone.id, empty_id: @site_to_clone.empty_id }) if @site_to_clone

    @site = Site.new(create_attrs)

    respond_to do |format|
      if @site.save
        @site.update_thumbnail_later

        # Only count clones by other users
        if @site_to_clone && @site_to_clone.user != current_user
          @site_to_clone.increment_clone_count
        end

        format.html { redirect_to sites_url }
        # format.json { render :show, status: :created, location: @site }
      else
        format.html { render :new }
        # format.json { render json: @site.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /sites/1
  # PATCH/PUT /sites/1.json
  def update
    respond_to do |format|
      if @site.update(site_params_for_update)
        format.html { redirect_to sites_url, notice: 'Site was successfully updated.' }
        # format.json { render :show, status: :ok, location: @site }
      else
        format.html { render :edit }
        # format.json { render json: @site.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /sites/1/upload
  # PATCH/PUT /sites/1/upload.json
  def upload
    respond_to do |format|
      new_content = params[:site][:tiddlywiki_file].read
      if @site.content_upload(new_content)
        @site.increment_save_count

        format.html { redirect_to sites_url, notice: 'Upload to site was successfully completed.' }
        # format.json { render :show, status: :ok, location: @site }
      else
        format.html { render :edit }
        # format.json { render json: @site.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /sites/1
  # DELETE /sites/1.json
  def destroy
    @site.destroy
    respond_to do |format|
      format.html { redirect_to sites_url, notice: 'Site was successfully destroyed.' }
      # format.json { head :no_content }
    end
  end

  private

  def set_site
    @site = current_user.sites.find(params[:id])
    redirect_to sites_url, notice: 'Site not found' unless @site
  end

  def set_sites
    # Doing some extra work here so that @site_count is correct when user is doing a text
    # search. It's needed because search filtering is done in sql before filter_results,
    # (and I don't feel like changing that).
    @sites = HubQuery.sites_for_user(current_user, sort_by: sort_sql)

    if search_text.present?
      # This is inefficient because we're doing the whole query again, but hopefully it won't matter
      sites_after_search = HubQuery.sites_for_user(current_user, search: search_text, sort_by: sort_sql)
    else
      sites_after_search = @sites
    end
    @filtered_sites = filter_results(sites_after_search)

    @site_count = @sites.count
    @filtered_site_count = @filtered_sites.count

    @total_storage_bytes = current_user.total_storage_bytes
  end

  def set_empties_list
    @empties_for_select = Empty.for_select
  end

  def site_params_for_create
    params.
      require(:site).
      permit(
        :name, :description, :is_private, :is_searchable, :tag_list, :allow_in_iframe,
        :prefer_put_saver, :prefer_upload_saver, :allow_public_clone, :skip_etag_check,
        :empty_id).
      merge(user_id: current_user.id)
  end

  def site_params_for_update
    params.
      require(:site).
      permit(
        :name, :description, :is_private, :is_searchable, :tag_list, :allow_in_iframe,
        :prefer_put_saver, :prefer_upload_saver, :allow_public_clone, :skip_etag_check)
  end

  # Sets @site_to_clone which will be nil if there's no clone param or if the
  # site to clone from isn't found. Note you can only clone your own site.
  #
  def set_site_to_clone
    site_to_clone_name = params.permit(:clone)[:clone]
    site_to_clone_maybe = Site.find_by_name(site_to_clone_name) if site_to_clone_name.present?
    @site_to_clone = site_to_clone_maybe if site_to_clone_maybe&.cloneable_by_user?(current_user)
  end
end
