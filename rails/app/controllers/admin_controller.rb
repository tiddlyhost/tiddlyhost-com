class AdminController < ApplicationController
  before_action :authenticate_user!
  before_action :require_admin_user!

  def users
    @users = User.all
    @title = "Users"
  end

  def sites
    if params[:user_id]
      @user = User.find(params[:user_id])
      @sites = Site.where(user: @user)
      @title = "#{@user.name} <#{@user.email}> sites"
    else
      @sites = Site.all
      @title = "All sites"
    end
  end

end
