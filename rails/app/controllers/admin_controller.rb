class AdminController < ApplicationController
  before_action :authenticate_user!
  before_action :require_admin_user!

  def index
    @title = 'Stats'

    @view_count = Site.sum(:view_count)
    @tspot_view_count = TspotSite.sum(:access_count)
    @total_site_bytes = ActiveStorage::Blob.sum(:byte_size)

    @user_count = User.count
    @never_signed_in_users = User.where(sign_in_count: 0).count
    @signed_in_once_users = User.where(sign_in_count: 1).count

    @site_count = Site.count
    @never_updated_sites = Site.never_updated.count
    @private_count = Site.private_sites.count
    @public_count = Site.public_sites.count
    @public_non_searchable_count = Site.public_non_searchable.count
    @searchable_count = Site.searchable.count

    @tspot_site_count = TspotSite.where(exists: true).count
    @notexist_tspot_site_count = TspotSite.where(exists: false).count
    @owned_tspot_site_count = TspotSite.where("user_id IS NOT NULL").count
    @tspot_sites_with_storage = TspotSite.joins(:tiddlywiki_file_attachment).count

  end

  def users
    @users = User.all
    @title = "Users"
  end

  def sites
    if params[:user_id]
      @user = User.find(params[:user_id])
      @sites = Site.where(user: @user)
      @title = "#{@user.username||@user.email}'s sites"
    else
      @sites = Site.all
      @title = "Sites"
    end
  end

  def tspot_sites
    if params[:user_id]
      @user = User.find(params[:user_id])
      @sites = TspotSite.where(user: @user)
      @title = "#{@user.username||@user.email}'s Tspot sites"
    else
      @sites = TspotSite.all
      @title = "Tiddlyspot Sites"
    end
  end

end
