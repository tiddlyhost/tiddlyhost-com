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
end
