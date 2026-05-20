require 'test_helper'

class CustomDomainAuthTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:bobby)
    @site = new_site_helper(user: @user, name: 'mydomainsite')
    @custom_domain = CustomDomain.create!(
      site: @site,
      domain: 'customtest.example.com',
      status: :active,
      ssl_status: :issued
    )
  end

  # -- Devise routes are NOT available on custom domains --

  test 'sign in is not routed on custom domain' do
    host! 'customtest.example.com'
    assert_raises(ActionController::RoutingError) { get '/users/sign_in' }
  end

  test 'sign up is not routed on custom domain' do
    host! 'customtest.example.com'
    assert_raises(ActionController::RoutingError) { get '/users/sign_up' }
  end

  test 'password reset is not routed on custom domain' do
    host! 'customtest.example.com'
    assert_raises(ActionController::RoutingError) { get '/users/password/new' }
  end

  test 'login shortcut is not routed on custom domain' do
    host! 'customtest.example.com'
    assert_raises(ActionController::RoutingError) { get '/login' }
  end

  # -- Devise routes still work on main site --

  test 'sign in page is available on main site' do
    get '/users/sign_in'
    assert_response :success
  end

  test 'sign up page is available on main site' do
    get '/users/sign_up'
    assert_response :success
  end

  test 'password reset page is available on main site' do
    get '/users/password/new'
    assert_response :success
  end

  # -- SSO routes on custom domain --

  test 'sso init redirects to main site authorize' do
    host! 'customtest.example.com'
    get '/sso/init'
    assert_response :redirect
    assert_match %r{#{Settings.main_site_host}/sso/authorize\?domain=customtest\.example\.com}, response.location
  end

  test 'sso callback with valid token signs in user' do
    token = SsoToken.generate(user_id: @user.id, domain: 'customtest.example.com')
    host! 'customtest.example.com'
    get "/sso/callback?token=#{CGI.escape(token)}"
    assert_response :redirect
    assert_redirected_to '/'
    # Verify user is signed in
    get '/'
    assert_response :success
  end

  test 'sso callback with invalid token returns forbidden' do
    host! 'customtest.example.com'
    get '/sso/callback?token=bogus'
    assert_response :forbidden
  end

  test 'sso callback with wrong domain returns forbidden' do
    token = SsoToken.generate(user_id: @user.id, domain: 'other.example.com')
    host! 'customtest.example.com'
    get "/sso/callback?token=#{CGI.escape(token)}"
    assert_response :forbidden
  end

  test 'sso callback with expired token returns forbidden' do
    token = SsoToken.generate(user_id: @user.id, domain: 'customtest.example.com')
    host! 'customtest.example.com'
    travel 6.minutes do
      get "/sso/callback?token=#{CGI.escape(token)}"
      assert_response :forbidden
    end
  end

  test 'sso callback respects return_to' do
    token = SsoToken.generate(user_id: @user.id, domain: 'customtest.example.com', return_to: '/download')
    host! 'customtest.example.com'
    get "/sso/callback?token=#{CGI.escape(token)}"
    assert_redirected_to '/download'
  end

  test 'logout on custom domain signs out' do
    token = SsoToken.generate(user_id: @user.id, domain: 'customtest.example.com')
    host! 'customtest.example.com'
    get "/sso/callback?token=#{CGI.escape(token)}"
    get '/logout'
    assert_redirected_to '/'
  end

  # -- SSO authorize on main site --

  test 'sso authorize redirects to custom domain callback when signed in' do
    sign_in @user
    get '/sso/authorize', params: { domain: 'customtest.example.com' }
    assert_response :redirect
    assert_match %r{https://customtest\.example\.com/sso/callback\?token=}, response.location
  end

  test 'sso authorize redirects to login when not signed in' do
    get '/sso/authorize', params: { domain: 'customtest.example.com' }
    assert_response :redirect
    assert_redirected_to new_user_session_path
  end

  test 'sso authorize returns forbidden for non-owner' do
    other_user = users(:mary)
    sign_in other_user
    get '/sso/authorize', params: { domain: 'customtest.example.com' }
    assert_response :forbidden
  end

  test 'sso authorize returns not found for unknown domain' do
    sign_in @user
    get '/sso/authorize', params: { domain: 'nonexistent.example.com' }
    assert_response :not_found
  end

  test 'sso authorize returns not found for inactive domain' do
    @custom_domain.update!(status: :verified)
    sign_in @user
    get '/sso/authorize', params: { domain: 'customtest.example.com' }
    assert_response :not_found
  end

  # -- Subdomain redirect --

  test 'tiddlyhost subdomain redirects to custom domain' do
    host! "#{@site.name}.#{Settings.main_site_host}"
    get '/'
    assert_response :found
    assert_redirected_to "https://#{@custom_domain.domain}/"
  end

  # -- Session invalidation --

  test 'invalidate_all_sessions invalidates custom domain session' do
    @site.update!(is_private: true)

    # SSO into custom domain
    token = SsoToken.generate(user_id: @user.id, domain: 'customtest.example.com')
    host! 'customtest.example.com'
    get "/sso/callback?token=#{CGI.escape(token)}"
    get '/'
    assert_response :success

    # Simulate "logout everywhere"
    @user.invalidate_all_sessions!

    # Custom domain session should now be invalid
    host! 'customtest.example.com'
    get '/'
    assert_response :unauthorized
  end

  # -- 401 page --

  test '401 page on custom domain links to sso init' do
    @site.update!(is_private: true)
    host! 'customtest.example.com'
    get '/'
    assert_response :unauthorized
    assert_select "a[href='/sso/init']", text: 'sign in'
  end

  test '401 page on main site links to tiddlyhost' do
    @site.update!(is_private: true)
    @custom_domain.destroy!
    host! "#{@site.name}.#{Settings.main_site_host}"
    get '/'
    assert_response :unauthorized
    assert_select "a[href*='#{Settings.main_site_host}']", text: 'Tiddlyhost'
  end

  # -- Save error messages --

  test 'put save error on custom domain mentions sso init url' do
    host! 'customtest.example.com'
    put '/', params: 'content', headers: { 'CONTENT_TYPE' => 'text/html' }
    assert_response :forbidden
    assert_match %r{customtest\.example\.com/sso/init}, response.body
  end

  test 'put save error on main site mentions main site url' do
    host! "#{@site.name}.#{Settings.main_site_host}"
    put '/', params: 'content', headers: { 'CONTENT_TYPE' => 'text/html' }
    assert_response :forbidden
    assert_match Settings.main_site_host, response.body
    refute_match %r{/sso/}, response.body
  end
end
