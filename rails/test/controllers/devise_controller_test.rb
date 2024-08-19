require 'test_helper'

class DeviseControllerTest < ActionDispatch::IntegrationTest
  #
  # Not really testing devise here, just smoke testing the various forms
  #
  test 'home page' do
    {
      '/users/sign_in' => 'Log in',
      '/users/sign_up' => 'Create account',
      '/users/confirmation/new' => 'Resend confirmation instructions',
      '/users/unlock/new' => 'Resend unlock instructions',

    }.each do |path, button_text|
      get path
      assert_response :success
      assert_select 'input[type=submit]' do |input|
        assert_equal button_text, input.first['value'], input.to_html
      end
    end
  end

  test 'account edit' do
    {
      '/users/edit' => 'Update',

    }.each do |path, button_text|
      sign_in users(:bobby)
      get path
      assert_response :success
      assert_select 'input[type=submit]' do |input|
        assert_equal button_text, input.first['value'], input.to_html
      end
    end
  end

  test 'account save changes' do
    user = User.create!(email: 'barry@tables.com', name: 'Barry', username: 'Baz', password: 'Abcd1234')
    user.confirm
    sign_in user

    # Without the password it should fail
    put '/users', params: { user: { name: 'Bazza' } }
    assert_response :success # I guess??
    # Todo: Should assert that the expected validation message appears
    assert_equal 'Barry', user.reload.name

    # With the password it should succeed
    put '/users', params: { user: { name: 'Bazza', current_password: 'Abcd1234' } }
    assert_redirected_to '/'
    assert_equal 'Bazza', user.reload.name
  end
end
