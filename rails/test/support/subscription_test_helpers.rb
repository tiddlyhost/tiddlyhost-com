module SubscriptionTestHelpers
  MockStripeProduct = Struct.new(:id, :name, :price)

  # Centralized Stripe product mocking for consistent test behavior
  # Call this in your test setup to mock all the common Settings methods
  def setup_stripe_product_mocking
    # Mock standard product configurations
    Settings.stubs(:stripe_product).with(:free).returns(
      MockStripeProduct.new(nil, 'Free Plan', 0))
    Settings.stubs(:stripe_product).with(:standard).returns(
      MockStripeProduct.new('price_standard', 'Standard Plan', 800))
    Settings.stubs(:stripe_product).with(:premium).returns(
      MockStripeProduct.new('price_premium', 'Premium Plan', 1500))

    # Mock frequency-specific products
    Settings.stubs(:stripe_product).with(:standard, :monthly).returns(
      MockStripeProduct.new('price_monthly_test', 'Standard Plan', 800))
    Settings.stubs(:stripe_product).with(:standard, :yearly).returns(
      MockStripeProduct.new('price_yearly_test', 'Standard Plan', 8000))

    # Mock product lookup by ID
    Settings.stubs(:stripe_product_by_id).with('price_test123').returns(
      MockStripeProduct.new('price_test123', 'Standard Plan', 800))
    # There is some fixture data that needs this
    Settings.stubs(:stripe_product_by_id).with('price_1MWtiXLudQhYOknor7RGBmCE').returns(
      MockStripeProduct.new('price_1MWtiXLudQhYOknor7RGBmCE', 'Standard Plan', 800))

    # Mock fallback for unknown products
    Settings.stubs(:stripe_product).with(:nonexistent).returns(nil)
  end

  # Helper for creating consistent pay customers in tests
  def create_test_pay_customer(user, processor_id: 'cus_test123')
    user.pay_customers.create!(
      processor: 'stripe',
      processor_id: processor_id,
      default: true
    )
  end

  # Helper for creating consistent subscriptions in tests
  def create_test_subscription(pay_customer, processor_id: 'sub_test123', plan: 'price_test123', status: 'active')
    pay_customer.subscriptions.create!(
      name: 'default',
      processor_id: processor_id,
      processor_plan: plan,
      status: status
    )
  end
end
