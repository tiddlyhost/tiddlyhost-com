require 'test_helper'

class SubscriptionControllerTest < ActionDispatch::IntegrationTest
  test 'feature flag disables this controller' do
    Settings::Features.stubs(:subscriptions_enabled?).returns(false)
    sign_in users(:bobby)
    %w[/subscription /subscription/plans /pricing].each do |path|
      get path
      assert_response :not_found
    end
  end

  test 'routes with authentication' do
    %w[/subscription /subscription/plans].each do |path|
      get path
      # Auth needed
      assert_redirected_to new_user_session_path
    end

    %w[/pricing].each do |path|
      get path
      # No auth needed
      assert_response :success
    end
  end
end
