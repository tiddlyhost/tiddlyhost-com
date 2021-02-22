
Rails.application.routes.draw do
  devise_for :users, controllers: { registrations: :registrations }

  #
  # For individual TiddlyWiki sites
  #
  constraints(->(req) { req.subdomain.present? && req.subdomain != 'www' }) do
    get '/', to: 'tiddlywiki#serve'
    get '/favicon.ico', to: 'tiddlywiki#favicon'
    get '/download', to: 'tiddlywiki#download'

    post '/', to: 'tiddlywiki#save'
  end

  #
  # For the 'main' site
  #
  constraints(->(req) { req.subdomain.blank? || req.subdomain == 'www' }) do
    root to: 'home#index'

    get 'home/index'
    get 'home/after_registration'

    get 'donate', to: 'home#donate'

    get 'admin/users'
    get 'admin/sites'

    get 'hub', to: 'hub#index'
    get "hub/tag/:tag", controller: :hub, action: :tag
    get "hub/user/:username", controller: :hub, action: :user

    resources :sites
  end

end
