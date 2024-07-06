# frozen_string_literal: true

require "test_helper"

class AdminControllerTest < ActionDispatch::IntegrationTest
  test "feature flag disables this controller" do
    Settings::Features.stub(:subscriptions_enabled?, false) do
      sign_in users(:bobby)

      get '/subscription'
      assert_response :not_found

      get '/subscription/plans'
      assert_response :not_found
    end
  end

  # Todo: Mock the stripe gem and test this controller properly
end
