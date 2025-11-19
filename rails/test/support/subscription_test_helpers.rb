module SubscriptionTestHelpers
  # Centralized Stripe product mocking for consistent test behavior
  # Call this in your test setup to mock all the common Settings methods
  def setup_stripe_product_mocking
    # Mock standard product configurations
    Settings.stubs(:stripe_product).with(:free).returns(
      OpenStruct.new(name: 'Free Plan', price: 0, id: nil)
    )
    Settings.stubs(:stripe_product).with(:standard).returns(
      OpenStruct.new(name: 'Standard Plan', price: 800, id: 'price_standard')
    )
    Settings.stubs(:stripe_product).with(:premium).returns(
      OpenStruct.new(name: 'Premium Plan', price: 1500, id: 'price_premium')
    )

    # Mock frequency-specific products
    Settings.stubs(:stripe_product).with(:standard, :monthly).returns(
      OpenStruct.new(id: 'price_monthly_test', name: 'Standard Plan', price: 800)
    )
    Settings.stubs(:stripe_product).with(:standard, :yearly).returns(
      OpenStruct.new(id: 'price_yearly_test', name: 'Standard Plan', price: 8000)
    )

    # Mock product lookup by ID
    Settings.stubs(:stripe_product_by_id).with('price_test123').returns(
      OpenStruct.new(name: 'Standard Plan', price: 800, id: 'price_test123')
    )
    # There is some fixture data that needs this
    Settings.stubs(:stripe_product_by_id).with('price_1MWtiXLudQhYOknor7RGBmCE').returns(
      OpenStruct.new(name: 'Standard Plan', price: 800, id: 'price_1MWtiXLudQhYOknor7RGBmCE')
    )

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
