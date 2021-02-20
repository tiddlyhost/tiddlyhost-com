require "test_helper"

class HubControllerTest < ActionDispatch::IntegrationTest

  test "should get index" do
    get '/hub'
    assert_response :success
  end

  test "tag urls" do
    get '/hub/tag/bananas'
    assert_response :success
  end

end
