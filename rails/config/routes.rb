Rails.application.routes.draw do
  #
  # Devise for user signups and authentication
  # (but exclude it for Tiddlyspot routes)
  #
  constraints(lambda { |req|
    req.domain != Settings.tiddlyspot_host
  }) do
    devise_for :users, controllers: {
      registrations: :registrations,
      sessions: :sessions,
    }
  end

  #
  # Individual sites on tiddlyhost.com
  #
  constraints(lambda { |req|
    req.domain == Settings.main_site_host && req.subdomain.present? && req.subdomain != 'www'
  }) do
    match '/', to: 'tiddlywiki#serve', via: [:get, :options]
    match '/tiddlers.json', to: 'tiddlywiki#json_content', via: [:get, :options]
    match '/text/:title.tid', to: 'tiddlywiki#tid_content', via: [:get, :options]

    get '/favicon.ico', to: 'tiddlywiki#favicon'
    get '/download', to: 'tiddlywiki#download'
    get '/thumb.png', to: 'tiddlywiki#thumb_png'

    post '/', to: 'tiddlywiki#upload_save'
    put '/', to: 'tiddlywiki#put_save'
  end

  #
  # The primary site at tiddlyhost.com
  #
  constraints(lambda { |req|
    req.domain == Settings.main_site_host && (req.subdomain.blank? || req.subdomain == 'www')
  }) do
    root to: 'home#index'

    get 'home/index'
    get 'home/after_registration'
    get 'home/mode_toggle'

    get 'about', to: 'home#about'
    get 'pricing', to: 'subscription#pricing'
    get 'donate', to: 'home#donate'
    get 'support', to: 'home#support'
    get 'privacy-policy', to: 'home#privacy_policy'
    get 'terms-of-use', to: 'home#terms_of_use'
    get 'favicon.ico', to: 'home#favicon'

    get 'admin', to: 'admin#index'

    get 'admin/charts'
    get 'admin/storage'
    get 'admin/users'
    get 'admin/sites'
    get 'admin/tspot_sites'
    get 'admin/etc'

    get 'admin/raw_download'
    get 'admin/boom'
    get 'admin/pool_stats'

    # These are variations on the same thing with a shared base class
    # See also HubController#redirect_hub_urls
    %w[hub browse explore templates].each do |c|
      get c, to: "#{c}#index"
      get "#{c}/tag/:tag", to: "#{c}#tag", constraints: { tag: /.+/ }
      get "#{c}/user/:username", to: "#{c}#user"
    end

    get 'subscription', to: 'subscription#show'
    get 'subscription/plans', to: 'subscription#plans'

    resources :sites do
      collection do
        get :view_toggle
      end

      member do
        get :download
        get :download_core_js
        get :upload_form
        patch :upload

        post :create_thumbnail

        # Related to save history
        get :history
        get 'view_version/favicon.ico', action: 'view_version_favicon'
        get 'view_version/:blob_id', action: 'view_version', as: :view_version
        get 'download_version/:blob_id', action: 'download_version', as: :download_version
        post 'restore_version/:blob_id', action: 'restore_version', as: :restore_version
        post 'discard_version/:blob_id', action: 'discard_version', as: :discard_version

        get 'version_label/:blob_id', action: 'version_label_form', as: :version_label_form
        patch 'version_label/:blob_id', action: 'version_label_update', as: :version_label_update
      end
    end

    if Settings.tiddlyspot_enabled?

      resources :tspot_sites do
        collection do
          get :claim_form
          post :claim
        end

        member do
          get :download
          post :disown
          post :delete

          get :change_password
          patch :change_password_submit

          post :create_thumbnail
        end
      end

    end
  end

  if Settings.tiddlyspot_enabled?
    #
    # Individual sites on tiddlyspot.com
    #
    constraints(lambda { |req|
      req.domain == Settings.tiddlyspot_host && req.subdomain.present? && req.subdomain != 'www'
    }) do
      get '/', to: 'tiddlyspot#serve'
      get '/index.html', to: 'tiddlyspot#serve'
      options '/', to: 'tiddlyspot#options'
      get '/favicon.ico', to: 'tiddlyspot#favicon'
      get '/download', to: 'tiddlyspot#download'
      get '/thumb.png', to: 'tiddlywiki#thumb_png'

      post '/store.cgi', to: 'tiddlyspot#save'
      post '/store.php', to: 'tiddlyspot#save'
    end

    #
    # Main tiddlyspot.com home page (such as it is)
    #
    constraints(lambda { |req|
      req.domain == Settings.tiddlyspot_host && (req.subdomain.blank? || req.subdomain == 'www')
    }) do
      get '/', to: 'tiddlyspot#home'
    end

  end

  #
  # Error pages
  #
  get '/404', to: 'home#error_404'
  get '/422', to: 'home#error_422'
  get '/500', to: 'home#error_500'
end
