require "test_helper"

class UserSignupTest < CapybaraIntegrationTest

  test "user signup" do
    name, email, password = 'Testy McTest', 'tmctest@mail.com', 'trustno1'

    # Visit home page and click sign up link
    visit '/'
    within(:css, '.jumbotron') { click_link 'Sign up' }

    # Fill in the sign up form fields
    fill_in 'user[name]', with: name
    fill_in 'user[email]', with: email
    fill_in 'user[password]', with: password
    fill_in 'user[password_confirmation]', with: password

    # Click the sign up button and confirm an email is sent
    assert_difference('ActionMailer::Base.deliveries.count') { click_button 'Create account' }

    # Confirm the "check email" page is shown
    assert page.has_content?('check your email for a confirmation link')

    # Sanity check the 'to' address in the confirmation email
    confirmation_email = ActionMailer::Base.deliveries.last
    assert_equal [email], confirmation_email.to

    # Extract the confirmation link from the email and click it
    confirmation_link = confirmation_email.body.match(/href="([^"]+)"/)[1]
    visit confirmation_link

    # Login
    fill_in 'user[email]', with: email
    fill_in 'user[password]', with: password
    click_button 'Log in'

    # Confirm we are logged in
    assert page.has_css?('h1', text: 'Your sites')

    # Logout
    click_link "Log out"

    # Confirm we are logged out
    assert page.has_css?(".jumbotron")

    # New user has the basic plan
    user = User.find_by_email('tmctest@mail.com')
    assert_equal 'basic', user.plan.name

  end

end
