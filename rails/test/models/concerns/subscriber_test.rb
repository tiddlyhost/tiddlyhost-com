require 'test_helper'

class SubscriberTest < ActiveSupport::TestCase
  def setup
    @user = users(:bobby)
  end

  test 'pay_customer creates payment processor when accessed' do
    # Test that user can create payment processor
    pay_customer = @user.pay_customers.create!(
      processor: 'stripe',
      processor_id: 'cus_test123',
      default: true
    )
    assert_not_nil pay_customer
    assert_equal 'stripe', pay_customer.processor
  end

  test 'checkout_session_for creates checkout session with monthly plan' do
    setup_stripe_product_mocking

    # Mock the payment processor checkout method
    mock_processor = mock('payment_processor')
    mock_processor.expects(:checkout).with(
      mode: 'subscription',
      line_items: 'price_monthly_test',
      success_url: "#{Settings.main_site_url}/subscription/success",
      cancel_url: "#{Settings.main_site_url}/subscription"
    ).returns('checkout_session_url')

    @user.stubs(:payment_processor).returns(mock_processor)

    result = @user.checkout_session_for(:standard, :monthly)
    assert_equal 'checkout_session_url', result
  end

  test 'checkout_session_for creates checkout session with yearly plan' do
    setup_stripe_product_mocking

    mock_processor = mock('payment_processor')
    mock_processor.expects(:checkout).with(
      mode: 'subscription',
      line_items: 'price_yearly_test',
      success_url: "#{Settings.main_site_url}/subscription/success",
      cancel_url: "#{Settings.main_site_url}/subscription"
    ).returns('checkout_session_url')

    @user.stubs(:payment_processor).returns(mock_processor)

    result = @user.checkout_session_for(:standard, :yearly)
    assert_equal 'checkout_session_url', result
  end

  test 'checkout_session_for raises error when price_id not found' do
    # Don't set up mocking for this specific product to test the error case
    Settings.stubs(:stripe_product).with(:premium, :monthly).returns(nil)

    assert_raises RuntimeError, "Can't find price id for :premium, :monthly!" do
      @user.checkout_session_for(:premium, :monthly)
    end
  end

  test 'checkout_session_for_price_id creates checkout session directly' do
    mock_processor = mock('payment_processor')
    mock_processor.expects(:checkout).with(
      mode: 'subscription',
      line_items: 'price_12345',
      success_url: "#{Settings.main_site_url}/subscription/success",
      cancel_url: "#{Settings.main_site_url}/subscription"
    ).returns('checkout_session_url')

    @user.stubs(:payment_processor).returns(mock_processor)

    result = @user.checkout_session_for_price_id('price_12345')
    assert_equal 'checkout_session_url', result
  end

  test 'subscription_info returns free plan when not subscribed' do
    setup_stripe_product_mocking
    @user.stubs(:subscribed?).returns(false)
    @user.stubs(:alt_subscription).returns(nil)

    result = @user.subscription_info
    assert_equal 'Free Plan', result.name
    assert_equal 0, result.price
  end

  test 'subscription_info returns subscription plan when subscribed with processor_plan' do
    setup_stripe_product_mocking
    @user.stubs(:subscribed?).returns(true)

    # Mock subscription with Stripe price ID (processor_plan)
    mock_subscription = mock('subscription')
    mock_subscription.stubs(:processor_plan).returns('price_1MWtiXLudQhYOknor7RGBmCE')
    @user.stubs(:subscription).returns(mock_subscription)

    result = @user.subscription_info
    assert_equal 'Standard Plan', result.name
    assert_equal 800, result.price
  end

  test 'subscription_info returns standard plan when subscribed but no processor_plan' do
    setup_stripe_product_mocking
    @user.stubs(:subscribed?).returns(true)

    # This tests the workaround/hack mentioned in the code comments
    mock_subscription = mock('subscription')
    mock_subscription.stubs(:processor_plan).returns(nil)
    @user.stubs(:subscription).returns(mock_subscription)

    result = @user.subscription_info
    assert_equal 'Standard Plan', result.name
    assert_equal 800, result.price
  end

  test 'subscription_info returns alt subscription when alt_subscription present' do
    setup_stripe_product_mocking
    @user.stubs(:subscribed?).returns(false)
    @user.stubs(:alt_subscription).returns('premium')

    result = @user.subscription_info
    assert_equal 'Premium Plan', result.name
    assert_equal 1500, result.price
  end

  test 'subscription_info falls back to free when alt_subscription not found' do
    setup_stripe_product_mocking
    @user.stubs(:subscribed?).returns(false)
    @user.stubs(:alt_subscription).returns('nonexistent')

    result = @user.subscription_info
    assert_equal 'Free Plan', result.name
    assert_equal 0, result.price
  end

  test 'has_subscription returns true when subscribed' do
    @user.stubs(:subscribed?).returns(true)
    @user.stubs(:alt_subscription).returns(nil)

    assert @user.has_subscription?
  end

  test 'has_subscription returns true when alt_subscription present' do
    @user.stubs(:subscribed?).returns(false)
    @user.stubs(:alt_subscription).returns('premium')

    assert @user.has_subscription?
  end

  test 'has_subscription returns false when no subscription' do
    @user.stubs(:subscribed?).returns(false)
    @user.stubs(:alt_subscription).returns(nil)

    refute @user.has_subscription?
  end

  test 'active_subscriptions scope filters for active status' do
    # Mock the subscriptions association and active scope
    mock_subscriptions = mock('pay_subscriptions')
    mock_subscriptions.expects(:where).with(status: 'active').returns(['subscription1', 'subscription2'])
    @user.stubs(:pay_subscriptions).returns(mock_subscriptions)

    result = @user.active_subscriptions
    assert_equal ['subscription1', 'subscription2'], result
  end

  test 'pay_customer_stripe returns stripe customer' do
    # Mock pay_customers association
    mock_customers = mock('pay_customers')
    mock_customer = mock('stripe_customer')
    mock_customers.expects(:where).with(processor: :stripe).returns([mock_customer])
    @user.stubs(:pay_customers).returns(mock_customers)

    result = @user.pay_customer_stripe
    assert_equal mock_customer, result
  end

  test 'scopes work correctly' do
    # Test the subscription-related scopes
    assert_respond_to User, :join_subscriptions
    assert_respond_to User, :with_subscriptions_active
  end
end
