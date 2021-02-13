class AdminController < ApplicationController
  before_action :authenticate_user!
  before_action :require_admin_user!

  def users
    @users = User.all
  end

  def sites
    @sites = Site.all
  end

end
