
require "test_helper"

class AdminControllerTest < ActionDispatch::IntegrationTest

  setup do
    @admin = users(:mary)
    @admin.update(plan: Plan.find_by_name('superuser'))
  end

  test "unauthorized user" do
    %w[
      /admin
      /admin/users

    ].each do |page|
      sign_in users(:bobby)
      get page
      assert_response :not_found
      assert_select 'h1', '404 Not Found', @response.body
    end
  end

  test "smoke test" do
    sign_in @admin
    %w[
      /admin
      /admin/users
      /admin/sites
      /admin/tspot_sites

    ].each do |page|
      get page
      assert_response :success
    end
  end

  test "csv data" do
    sign_in @admin
    get '/admin/csv_data'
    @response.body.lines.each do |line|
      assert_match /^\d\d\d\d-\d\d-\d\d,\d$/, line
    end
  end

end
