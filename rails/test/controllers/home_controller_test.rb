require "test_helper"

class HomeControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get '/'
    assert_response :success
    assert_select '.jumbotron h3', 'Get started now'
  end

  # Fixme
  #test "site subdomain routes correctly" do
  #  get '/', headers: { host: "foo.#{Settings.main_hostname}" }
  #  assert_response :success
  #  assert_match 'todo', @response.body
  #end

  test "www subdomain should redirect" do
    get home_index_url, headers: { host: "www.#{Settings.url_defaults[:host]}" }
    assert_redirected_to(Settings.url_defaults)
  end
end
