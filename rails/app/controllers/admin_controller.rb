class AdminController < ApplicationController
  before_action :authenticate_user!
  before_action :require_admin_user!

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
      @title = "All sites"
    end
  end

end
