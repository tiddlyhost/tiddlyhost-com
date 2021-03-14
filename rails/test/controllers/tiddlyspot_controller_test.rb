require "test_helper"

class TiddlyspotControllerTest < ActionDispatch::IntegrationTest

  test "home page" do
    host! Settings.tiddlyspot_host
    get '/'
    assert_response :success
    assert_match 'Tiddlyspot is now in recovery mode', response.body
  end

  test "www redirect" do
    host! "www.#{Settings.tiddlyspot_host}"
    get '/'
    assert_redirected_to Settings.tiddlyspot_url_defaults
    assert_redirected_to "http://tiddlyspot-example.com/"
  end

end
