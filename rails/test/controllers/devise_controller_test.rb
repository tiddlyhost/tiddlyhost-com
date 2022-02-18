require "test_helper"

class DeviseControllerTest < ActionDispatch::IntegrationTest

  #
  # Not really testing devise here, just smoke testing the various forms
  #
  test "home page" do
    {
      '/users/sign_in' => 'Log in',
      '/users/sign_up' => 'Create account',
      '/users/confirmation/new' => 'Resend confirmation instructions',
      '/users/unlock/new' => 'Resend unlock instructions',

    }.each do |path, button_text|
      get path
      assert_response :success
      assert_select 'input[type=submit]' do |input|
        assert_equal button_text, input.first["value"], input.to_html
      end
    end
  end

  test "account edit" do
    {
      '/users/edit' => 'Update',

    }.each do |path, button_text|
      sign_in users(:bobby)
      get path
      assert_response :success
      assert_select 'input[type=submit]' do |input|
        assert_equal button_text, input.first["value"], input.to_html
      end
    end
  end

end
