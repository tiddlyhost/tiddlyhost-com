require 'test_helper'

class UserSignupTest < CapybaraIntegrationTest
  test 'user signup' do
    name, email, username, weak_password, strong_password =
      'Testy McTest', 'tmctest@mail.com', 'tmt', 'trstno1', 'trUst|no1'

    # Visit home page and click sign up link
    visit '/'
    within(:css, '.jumbotron') { click_link 'Sign up' }

    # Fill in the sign up form fields
    fill_in 'user[name]', with: name
    fill_in 'user[email]', with: email
    fill_in 'user[username]', with: username
    fill_in 'user[password]', with: weak_password
    fill_in 'user[password_confirmation]', with: weak_password

    # Submit
    click_button 'Create account'

    # Password is not strong enough...
    assert page.has_content?('Password is too short')
    assert page.has_content?('Password must contain at least one upper-case letter')

    # Try again
    fill_in 'user[password]', with: strong_password
    fill_in 'user[password_confirmation]', with: strong_password

    # Click the sign up button and confirm an email is sent
    assert_difference('ActionMailer::Base.deliveries.count') { click_button 'Create account' }

    # Confirm the "check email" page is shown
    assert page.has_content?('please click the confirmation link')

    # Sanity check the 'to' address in the confirmation email
    confirmation_email = ActionMailer::Base.deliveries.last
    assert_equal [email], confirmation_email.to

    # Extract the confirmation link from the email and click it
    confirmation_link = confirmation_email.html_part.body.decoded.match(%r{href="([^"]+)">Confirm account</a>})[1]
    visit confirmation_link

    # Login
    fill_in 'user[email]', with: email
    fill_in 'user[password]', with: strong_password
    click_button 'Log in'

    # Confirm we are logged in
    assert page.has_css?('h1', text: 'Your sites')

    # Logout
    click_link 'Log out'

    # Confirm we are logged out
    assert page.has_css?('.jumbotron')

    # New user has the basic user type
    user = User.find_by_email('tmctest@mail.com')
    assert_equal 'basic', user.user_type.name
  end
end
