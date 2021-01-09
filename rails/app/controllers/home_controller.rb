class HomeController < ApplicationController
  before_action :authenticate_user!, except: [:index, :todo, :after_registration]

  def index
  end

  def todo
  end

  def after_registration
    render template: 'devise/registrations/after_registration'
  end

end
