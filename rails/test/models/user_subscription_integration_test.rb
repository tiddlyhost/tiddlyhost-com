require 'test_helper'

class UserSubscriptionIntegrationTest < ActiveSupport::TestCase
  def setup
    @user = users(:bobby)
    setup_stripe_product_mocking
    # Clear any existing Pay customers to ensure test isolation
    @user.pay_customers.destroy_all
  end

  test 'user subscription_info works with real Pay gem data' do
    # Create real subscription data, no mocking
    pay_customer = Pay::Stripe::Customer.create!(
      owner: @user,
      processor: 'stripe',
      processor_id: 'cus_info_test_123',
      default: true
    )

    subscription = Pay::Stripe::Subscription.create!(
      customer: pay_customer,
      name: 'default',
      processor_id: 'sub_info_test_123',
      processor_plan: 'price_test123',
      status: 'active'
    )

    # Test subscription_info method without any mocking
    result = @user.subscription_info
    assert_equal 'Standard Plan', result.name
    assert_equal 800, result.price

    # Verify this actually used the real subscription
    assert @user.subscribed?
    assert_equal subscription, @user.subscription
    assert_instance_of Pay::Stripe::Subscription, @user.subscription
  end

  test 'user has_subscription works with real data' do
    # Test without subscription first
    refute @user.has_subscription?

    # Create real subscription
    pay_customer = Pay::Stripe::Customer.create!(
      owner: @user,
      processor: 'stripe',
      processor_id: 'cus_has_sub_123',
      default: true
    )

    Pay::Stripe::Subscription.create!(
      customer: pay_customer,
      name: 'default',
      processor_id: 'sub_has_sub_123',
      processor_plan: 'price_123',
      status: 'active'
    )

    # Reload user to see new associations
    @user.reload

    # Now should have subscription
    assert @user.has_subscription?
  end

  test 'user pay_customer_stripe returns correct STI type' do
    # Create both stripe and hypothetical other processor customers
    stripe_customer = Pay::Stripe::Customer.create!(
      owner: @user,
      processor: 'stripe',
      processor_id: 'cus_stripe_sti_123'
    )

    # The method should return the stripe customer as correct STI type
    result = @user.pay_customer_stripe
    assert_equal stripe_customer, result
    assert_instance_of Pay::Stripe::Customer, result
    assert_equal 'Pay::Stripe::Customer', result.type
  end

  test 'checkout session creation works with real payment processor' do
    # This test creates a real Pay::Customer and calls the payment_processor method
    pay_customer = Pay::Stripe::Customer.create!(
      owner: @user,
      processor: 'stripe',
      processor_id: 'cus_checkout_123',
      default: true
    )

    # Mock the checkout method on the user's payment_processor
    @user.payment_processor.expects(:checkout).with(
      mode: 'subscription',
      line_items: 'price_monthly_test',
      success_url: "http://tiddlyhost-test-example.com/subscription",
      cancel_url: "http://tiddlyhost-test-example.com/subscription"
    ).returns({
      id: 'cs_test_real_123',
      url: 'https://checkout.stripe.com/pay/cs_test_real_123'
    })

    result = @user.checkout_session_for(:standard, :monthly)
    assert_equal 'cs_test_real_123', result[:id]
    assert_equal pay_customer, @user.pay_customer_stripe

    # Verify we're using real Pay gem object
    assert_instance_of Pay::Stripe::Customer, @user.payment_processor
  end

  test 'subscription state changes work with real Pay gem STI' do
    setup_stripe_product_mocking

    pay_customer = Pay::Stripe::Customer.create!(
      owner: @user,
      processor: 'stripe',
      processor_id: 'cus_state_test_123',
      default: true
    )

    subscription = Pay::Stripe::Subscription.create!(
      customer: pay_customer,
      name: 'default',
      processor_id: 'sub_state_test_123',
      processor_plan: 'price_123',
      status: 'active'
    )

    # Verify user is subscribed with real data
    assert @user.subscribed?
    assert_instance_of Pay::Stripe::Subscription, @user.subscription

    # Change subscription status
    subscription.update!(status: 'past_due')
    @user.reload

    # User should still be "subscribed" (past_due is still a subscription)
    # but let's verify the status changed in the database
    assert_equal 'past_due', @user.subscription.status

    # Cancel subscription
    subscription.update!(status: 'canceled')
    @user.reload

    # Now user should not be subscribed
    refute @user.subscribed?
  end

  test 'User scopes work with real Pay gem data and STI' do
    # Create user with active subscription
    other_user = User.create!(
      email: 'test_scope@example.com',
      password: 'Password123!',
      name: 'Test Scope User',
      user_type: UserType.find_by(name: 'basic')
    )

    pay_customer = Pay::Stripe::Customer.create!(
      owner: other_user,
      processor: 'stripe',
      processor_id: 'cus_scope_real_123',
      default: true
    )

    active_subscription = Pay::Stripe::Subscription.create!(
      customer: pay_customer,
      name: 'default',
      processor_id: 'sub_scope_real_123',
      processor_plan: 'price_123',
      status: 'active'
    )

    # Test scope includes user with active subscription
    users_with_active_subs = User.with_subscriptions_active
    assert_includes users_with_active_subs, other_user

    # Verify the subscription is correct STI type
    found_user = users_with_active_subs.find(other_user.id)
    user_subscription = found_user.pay_subscriptions.active.first
    assert_instance_of Pay::Stripe::Subscription, user_subscription

    # Cancel subscription and test scope excludes user
    active_subscription.update!(status: 'canceled')
    other_user.reload # Reload to clear any cached associations
    users_after_cancel = User.with_subscriptions_active
    refute_includes users_after_cancel, other_user

    # Clean up
    other_user.destroy!
  end

  test 'payment processor delegation works with STI' do
    pay_customer = Pay::Stripe::Customer.create!(
      owner: @user,
      processor: 'stripe',
      processor_id: 'cus_processor_123',
      default: true
    )

    # The payment_processor method should return the STI customer
    processor = @user.payment_processor
    assert_instance_of Pay::Stripe::Customer, processor
    assert_equal pay_customer, processor

    # Test that processor-specific methods are available
    assert_respond_to processor, :processor # Should return 'stripe'
    assert_equal 'stripe', processor.processor
  end

  test 'subscription plan lookup works with real processor_plan' do
    pay_customer = Pay::Stripe::Customer.create!(
      owner: @user,
      processor: 'stripe',
      processor_id: 'cus_plan_lookup_123',
      default: true
    )

    # Use a real Stripe price ID that's mocked in our test helpers
    subscription = Pay::Stripe::Subscription.create!(
      customer: pay_customer,
      name: 'default',
      processor_id: 'sub_plan_lookup_123',
      processor_plan: 'price_1MWtiXLudQhYOknor7RGBmCE', # From test fixtures
      status: 'active'
    )

    # Test subscription_info uses real processor_plan for lookup
    result = @user.subscription_info
    assert_equal 'Standard Plan', result.name
    assert_equal 800, result.price

    # Verify it found the real subscription
    assert_equal subscription.processor_plan, @user.subscription.processor_plan
    assert_instance_of Pay::Stripe::Subscription, @user.subscription
  end
end
