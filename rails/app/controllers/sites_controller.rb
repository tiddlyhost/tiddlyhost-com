
class SitesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_site, except: [:index, :new, :create]
  before_action :set_empties_list, only: [:new, :create]

  SORT_OPTIONS = {
    compressed: 'size',
    kind: 'tw_kind',
    name: 'name',
    updated: 'blob_created_at',
    version: 'tw_kind,tw_version',
    access: 'not_searchable,is_private',
    views: 'view_count',
    size: 'raw_size',
  }

  NULL_ALWAYS_LAST = %w[
    version
    size
  ]

  # GET /sites
  # GET /sites.json
  def index
    # Todo: DRY this (see admin controller)
    @sort_by = (params[:s].dup || 'updated_desc')
    @is_desc = @sort_by.sub!(/_desc$/, '')
    null_always_last = NULL_ALWAYS_LAST.include?(@sort_by)
    sort_field = SORT_OPTIONS[@sort_by.to_sym] || SORT_OPTIONS[:updated]
    desc_sql = @is_desc ? "DESC NULLS LAST" : "ASC NULLS #{null_always_last ? 'LAST' : 'FIRST'}"
    sort_by = sort_field.split(',').map{|f| "#{f} #{desc_sql}"}.join(",")

    @sites = HubQuery.sites_for_user(current_user, sort_by: sort_by)
    @site_count = @sites.count
    @total_storage_bytes = current_user.total_storage_bytes
  end

  # GET /sites/1
  # GET /sites/1.json
  def show
  end

  # GET /sites/1/download
  def download
    download_html_content(@site.download_content, @site.name)
  end

  # GET /sites/new
  def new
    @site = Site.new
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
    @empty = Empty.find(site_params_for_create[:empty_id])

    @site = Site.new(
      site_params_for_create.merge(SiteCommon.attachment_params(@empty.html)))

    respond_to do |format|
      if @site.save
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
    # (Could consider combining this with update, but for now it's separate)
    respond_to do |format|
      if @site.update(site_params_for_upload)
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

  def set_empties_list
    @empties_for_select = Empty.for_select
  end

  def site_params_for_create
    params.
      require(:site).
      permit(:name, :description, :is_private, :is_searchable, :tag_list, :allow_in_iframe, :enable_put_saver, :empty_id).
      merge(user_id: current_user.id)
  end

  def site_params_for_update
    params.
      require(:site).
      permit(:name, :description, :is_private, :is_searchable, :tag_list, :allow_in_iframe, :enable_put_saver)
  end

  def site_params_for_upload
    new_content = params[:site][:tiddlywiki_file].read
    params.
      require(:site).
      permit(:tiddlywiki_file).
      merge(SiteCommon.attachment_params(new_content))
  end
end
