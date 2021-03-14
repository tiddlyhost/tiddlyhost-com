require "test_helper"

class HomeControllerTest < ActionDispatch::IntegrationTest

  test "should get index" do
    get '/'
    assert_response :success
    assert_select '.jumbotron h3', 'Get started now'
  end

  test "www subdomain should redirect" do
    host! "www.#{Settings.main_site_host}"
    get '/'
    assert_redirected_to Settings.url_defaults
  end

  # See also test/integration/sites_test.rb
end
