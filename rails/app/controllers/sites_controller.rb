
class SitesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_site, except: [:index, :new, :create]
  before_action :set_empties_list, only: [:new, :create]

  # GET /sites
  # GET /sites.json
  def index
    @sites = current_user.all_sites.sort_by(&:updated_at).reverse
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
        # Make sure the version select is shown if it needs to be
        @show_advanced = @site.empty_id != @default_empty.id

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
    @default_empty = Empty.default
  end

  def site_params_for_create
    params.
      require(:site).
      permit(:name, :description, :is_private, :is_searchable, :tag_list, :allow_in_iframe, :empty_id).
      merge(user_id: current_user.id)
  end

  def site_params_for_update
    params.
      require(:site).
      permit(:name, :description, :is_private, :is_searchable, :tag_list, :allow_in_iframe)
  end

  def site_params_for_upload
    new_content = params[:site][:tiddlywiki_file].read
    params.
      require(:site).
      permit(:tiddlywiki_file).
      merge(SiteCommon.attachment_params(new_content))
  end
end
