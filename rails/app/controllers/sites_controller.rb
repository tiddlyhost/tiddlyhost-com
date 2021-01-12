require 'tiddlywiki_empty'

class SitesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_site, only: [:show, :edit, :update, :destroy]

  # GET /sites
  # GET /sites.json
  def index
    @sites = current_user.sites
  end

  # GET /sites/1
  # GET /sites/1.json
  def show
  end

  # GET /sites/new
  def new
    @site = Site.new
  end

  # GET /sites/1/edit
  def edit
  end

  # POST /sites
  # POST /sites.json
  def create

    tiddlywiki_file = {
      # These are the params used by active storage
      io: StringIO.new(TiddlywikiEmpty.modified_empty(site_params_for_create[:name])),
      filename: 'index.html',
      content_type: 'text/html',
    }

    @site = Site.new(site_params_for_create.merge(tiddlywiki_file: tiddlywiki_file))

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
    redirect_to sites_url notice: 'Site not found' unless @site
  end

  def site_params_for_create
    params.require(:site).permit(:name, :is_private).merge(user_id: current_user.id)
  end

  def site_params_for_update
    params.require(:site).permit(:name, :is_private)
  end
end
