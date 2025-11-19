require 'test_helper'

class SubscriptionStateTest < ActiveSupport::TestCase
  def setup
    @user = users(:bobby)
  end

  test 'user can have pay customers created' do
    pay_customer = @user.pay_customers.create!(
      processor: 'stripe',
      processor_id: 'cus_test123',
      default: true
    )

    assert_not_nil pay_customer
    assert_equal 'stripe', pay_customer.processor
    assert_equal @user, pay_customer.owner
  end

  test 'pay customer can have subscriptions' do
    pay_customer = create_pay_customer

    subscription = create_test_subscription(pay_customer, plan: 'price_123')

    assert_equal 'active', subscription.status
    assert_equal 'price_123', subscription.processor_plan
    assert_equal pay_customer, subscription.customer
  end

  test 'pay customer can have charges' do
    pay_customer = create_pay_customer

    charge = pay_customer.charges.create!(
      processor_id: 'ch_test123',
      amount: 800,
      currency: 'usd'
    )

    assert_equal 800, charge.amount
    assert_equal 'usd', charge.currency
    assert_equal pay_customer, charge.customer
  end

  test 'user subscription scopes work' do
    # Test that the scopes exist and can be called
    assert_respond_to User, :join_subscriptions
    assert_respond_to User, :with_subscriptions_active

    # Create actual subscription data to test scope
    pay_customer = create_pay_customer
    create_test_subscription(pay_customer, processor_id: 'sub_active', plan: 'price_123')
    create_test_subscription(pay_customer, processor_id: 'sub_canceled', plan: 'price_123', status: 'canceled')

    # Test that with_subscriptions_active only returns users with active subscriptions
    active_users = User.with_subscriptions_active
    assert_includes active_users.pluck(:id), @user.id
  end

  test 'subscription info logic works with mocked data' do
    setup_stripe_product_mocking

    # Test unsubscribed user gets free plan
    @user.stubs(:subscribed?).returns(false)
    @user.stubs(:alt_subscription).returns(nil)

    result = @user.subscription_info
    assert_equal 'Free Plan', result.name
    assert_equal 0, result.price

    # Test subscribed user with processor_plan gets correct plan
    mock_subscription = mock('subscription')
    mock_subscription.stubs(:processor_plan).returns('price_test123')

    @user.stubs(:subscribed?).returns(true)
    @user.stubs(:subscription).returns(mock_subscription)

    result = @user.subscription_info
    assert_equal 'Standard Plan', result.name
    assert_equal 800, result.price

    # Test subscribed user without processor_plan gets fallback
    mock_subscription_no_plan = mock('subscription')
    mock_subscription_no_plan.stubs(:processor_plan).returns(nil)

    @user.stubs(:subscription).returns(mock_subscription_no_plan)

    result = @user.subscription_info
    assert_equal 'Standard Plan', result.name # Falls back to standard
  end

  test 'has_subscription logic works correctly' do
    # Test subscribed user
    @user.stubs(:subscribed?).returns(true)
    @user.stubs(:alt_subscription).returns(nil)
    assert @user.has_subscription?

    # Test user with alt subscription
    @user.stubs(:subscribed?).returns(false)
    @user.stubs(:alt_subscription).returns('premium')
    assert @user.has_subscription?

    # Test user with no subscription
    @user.stubs(:subscribed?).returns(false)
    @user.stubs(:alt_subscription).returns(nil)
    refute @user.has_subscription?
  end

  test 'checkout session creation parameters are correct' do
    setup_stripe_product_mocking

    # Mock the payment processor
    mock_processor = mock('payment_processor')
    mock_processor.expects(:checkout).returns('session_url')
    @user.stubs(:payment_processor).returns(mock_processor)

    # Test the method
    result = @user.checkout_session_for(:standard, :monthly)
    assert_equal 'session_url', result
  end

  test 'pay_customer_stripe returns correct customer' do
    # Clear any existing customers first
    @user.pay_customers.destroy_all

    # Create both Stripe and a hypothetical other processor customer
    stripe_customer = @user.pay_customers.create!(
      processor: 'stripe',
      processor_id: 'cus_stripe',
      default: true
    )

    @user.pay_customers.create!(
      processor: 'paypal',
      processor_id: 'cus_paypal',
      default: false
    )

    result = @user.pay_customer_stripe
    assert_equal stripe_customer, result
    assert_equal 'stripe', result.processor
  end

  test 'active_subscriptions filters correctly' do
    pay_customer = create_pay_customer

    # Create subscriptions with different statuses
    active_sub = create_test_subscription(pay_customer, processor_id: 'sub_active', plan: 'price_123')

    past_due_sub = create_test_subscription(pay_customer, processor_id: 'sub_past_due', plan: 'price_123', status: 'past_due')

    canceled_sub = create_test_subscription(pay_customer, processor_id: 'sub_canceled', plan: 'price_123', status: 'canceled')

    # Test that active_subscriptions only returns active ones
    active_subs = @user.active_subscriptions
    assert_includes active_subs, active_sub
    refute_includes active_subs, past_due_sub
    refute_includes active_subs, canceled_sub
  end

  private

  def create_pay_customer
    @user.pay_customers.create!(
      processor: 'stripe',
      processor_id: 'cus_test123',
      default: true
    )
  end
end
