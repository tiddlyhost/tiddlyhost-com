class HomeController < ApplicationController

  def index
    if user_signed_in?
      redirect_to sites_path
    end
  end

  def after_registration
    render template: 'devise/registrations/after_registration'
  end

  def donate
  end

  def build_info
    @build_info = YAML.load(File.read(Rails.root.join('public', 'build-info.txt')))
  end

end
