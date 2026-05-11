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

  # -- Devise route availability on custom domains --

  test 'sign in page is available on custom domain' do
    host! 'customtest.example.com'
    get '/users/sign_in'
    assert_response :success
    assert_select 'input[type=submit][value="Log in"]'
  end

  test 'sign up is not routed on custom domain' do
    host! 'customtest.example.com'
    assert_raises(ActionController::RoutingError) { get '/users/sign_up' }
  end

  test 'password reset is not routed on custom domain' do
    host! 'customtest.example.com'
    assert_raises(ActionController::RoutingError) { get '/users/password/new' }
  end

  test 'confirmation is not routed on custom domain' do
    host! 'customtest.example.com'
    assert_raises(ActionController::RoutingError) { get '/users/confirmation/new' }
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

  # -- Links in login form point to main site --

  test 'sign up link on custom domain points to main site' do
    host! 'customtest.example.com'
    get '/users/sign_in'
    assert_select "a[href*='#{Settings.main_site_host}/users/sign_up']"
  end

  test 'forgot password link on custom domain points to main site' do
    host! 'customtest.example.com'
    get '/users/sign_in'
    assert_select "a[href*='#{Settings.main_site_host}/users/password/new']"
  end

  # -- Devise routes are not available on inactive custom domains --

  test 'sign in is blocked on inactive custom domain' do
    @custom_domain.update!(status: :verified)
    host! 'customtest.example.com'
    get '/users/sign_in'
    # Host authorization blocks requests to non-active custom domains
    assert_response :forbidden
  end

  # -- Session cookie domain --

  test 'session cookie domain is overridden for custom domains' do
    host! 'customtest.example.com'
    get '/users/sign_in'
    # The session options should have been set for the custom domain
    assert_response :success
  end

  # -- /login redirect --

  test 'login shortcut redirects to sign in on custom domain' do
    host! 'customtest.example.com'
    get '/login'
    assert_redirected_to '/users/sign_in'
  end

  test 'login shortcut is not routed on main site' do
    assert_raises(ActionController::RoutingError) { get '/login' }
  end

  # -- After sign-in redirect --

  test 'after sign in on custom domain redirects to root' do
    host! 'customtest.example.com'
    sign_in @user
    get '/'
    assert_response :success
  end

  # -- 401 page on custom domain --

  test '401 page on custom domain links to /login' do
    @site.update!(is_private: true)
    host! 'customtest.example.com'
    get '/'
    assert_response :unauthorized
    assert_select "a[href='/users/sign_in']", text: 'sign in'
  end

  test 'tiddlyhost subdomain redirects to custom domain' do
    host! "#{@site.name}.#{Settings.main_site_host}"
    get '/'
    assert_response :found
    assert_redirected_to "https://#{@custom_domain.domain}/"
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

  test 'put save error on custom domain mentions custom domain login url' do
    host! 'customtest.example.com'
    put '/', params: 'content', headers: { 'CONTENT_TYPE' => 'text/html' }
    assert_response :forbidden
    assert_match %r{customtest\.example\.com/login}, response.body
  end

  test 'put save error on main site mentions main site url' do
    host! "#{@site.name}.#{Settings.main_site_host}"
    put '/', params: 'content', headers: { 'CONTENT_TYPE' => 'text/html' }
    assert_response :forbidden
    assert_match Settings.main_site_host, response.body
    refute_match %r{/login}, response.body
  end
end
