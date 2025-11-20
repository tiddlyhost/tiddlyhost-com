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

  test 'pricing page for unauthed user' do
    setup_stripe_product_mocking
    Pay::Stripe.stubs(:public_key).returns('pk_test_123')

    get '/pricing'
    assert_response :success
    assert_match 'Sign up', response.body
  end

  test 'subscription pages for authed user' do
    setup_stripe_product_mocking
    setup_authed_user_with_stubs

    get '/subscription'
    assert_response :success
    assert_match 'Subscribe now', response.body

    get '/subscription/plans'
    assert_response :success
    assert_match 'Subscribe now', response.body

    # Same as /subscription/plans iirc
    get '/pricing'
    assert_response :success
    assert_match 'Subscribe now', response.body
  end

  def setup_authed_user_with_stubs
    # Mock Stripe public key for the checkout button partial
    Pay::Stripe.stubs(:public_key).returns('pk_test_123')

    # Mock the payment processor methods that get called in set_user_vars
    # We need to stub the methods that will be called on the actual user object
    User.any_instance.stubs(:set_payment_processor).returns(nil)
    User.any_instance.stubs(:billing_portal).returns(nil)
    User.any_instance.stubs(:subscribed?).returns(false)
    User.any_instance.stubs(:subscription).returns(nil)
    User.any_instance.stubs(:subscription_info).returns(Settings.stripe_product(:free))
    User.any_instance.stubs(:checkout_session_for_price_id).returns(Struct.new(:id).new('cs_test123'))

    # Sign in a user
    sign_in(users(:bobby))
  end
end
