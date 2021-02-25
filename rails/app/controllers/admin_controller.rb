class AdminController < ApplicationController
  before_action :authenticate_user!
  before_action :require_admin_user!

  def index
    @title = 'Stats'

    @view_count = Site.sum(:view_count)

    @user_count = User.count
    @never_signed_in_users = User.where(sign_in_count: 0).count
    @signed_in_once_users = User.where(sign_in_count: 1).count

    @site_count = Site.count
    @never_updated_sites = Site.never_updated.count
    @private_count = Site.private_sites.count
    @public_count = Site.public_sites.count
    @public_non_searchable_count = Site.public_non_searchable.count
    @searchable_count = Site.searchable.count

  end

  def users
    @users = User.without_plan(:superuser)
    @title = "Users"
  end

  def sites
    if params[:user_id]
      @user = User.find(params[:user_id])
      @sites = Site.where(user: @user)
      @title = "#{@user.name} #{"'#{@user.username}'" if @user.has_username?} <#{@user.email}> sites"
    else
      @sites = Site.all
      @title = "Sites"
    end
  end

end
