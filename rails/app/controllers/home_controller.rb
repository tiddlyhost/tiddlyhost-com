class HomeController < ApplicationController
  before_action :authenticate_user!, except: [:index, :todo]

  def index
  end

  def todo
  end

end
