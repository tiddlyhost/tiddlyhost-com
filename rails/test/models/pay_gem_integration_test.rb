require 'test_helper'

class PayGemIntegrationTest < ActiveSupport::TestCase
  def setup
    @user = users(:bobby)
    # Clear any existing Pay customers to ensure test isolation
    @user.pay_customers.destroy_all
  end

  test 'Pay gem migration adds type column correctly' do
    # This test verifies the type column exists and can be queried
    assert Pay::Customer.column_names.include?('type'), 'type column should exist after migration'
    assert Pay::Subscription.column_names.include?('type'), 'type column should exist after migration'
    assert Pay::Charge.column_names.include?('type'), 'type column should exist after migration'
  end

  test 'user subscription methods work with real Pay gem data' do
    # Create real Pay gem records, no mocking
    pay_customer = Pay::Stripe::Customer.create!(
      owner: @user,
      processor: 'stripe',
      processor_id: 'cus_real_test_123',
      default: true
    )

    subscription = Pay::Stripe::Subscription.create!(
      customer: pay_customer,
      name: 'default',
      processor_id: 'sub_real_test_123',
      processor_plan: 'price_test123',
      status: 'active'
    )

    # Test the actual methods without mocking
    assert @user.subscribed?, 'User should be subscribed with real subscription'
    assert_equal subscription, @user.subscription, 'Should return the actual subscription'

    # Test STI types
    assert_instance_of Pay::Stripe::Customer, pay_customer
    assert_instance_of Pay::Stripe::Subscription, subscription
  end

  test 'Pay Customer querying works with STI' do
    # Create customers for different processors
    stripe_customer = Pay::Stripe::Customer.create!(
      owner: @user,
      processor: 'stripe',
      processor_id: 'cus_stripe_123'
    )

    # Query customers by processor - this relies on STI working correctly
    stripe_customers = Pay::Stripe::Customer.where(processor: 'stripe')
    assert_includes stripe_customers, stripe_customer

    # Verify the returned object is the correct STI type
    found_customer = stripe_customers.find_by(processor_id: 'cus_stripe_123')
    assert_instance_of Pay::Stripe::Customer, found_customer
    assert_equal 'Pay::Stripe::Customer', found_customer.type
  end

  test 'user active_subscriptions scope works with real data' do
    pay_customer = Pay::Customer.create!(
      owner: @user,
      processor: 'stripe',
      processor_id: 'cus_active_test_123',
      default: true
    )

    # Create active subscription
    active_sub = Pay::Stripe::Subscription.create!(
      customer: pay_customer,
      name: 'default',
      processor_id: 'sub_active_123',
      processor_plan: 'price_123',
      status: 'active'
    )

    # Create canceled subscription
    canceled_sub = Pay::Stripe::Subscription.create!(
      customer: pay_customer,
      name: 'canceled',
      processor_id: 'sub_canceled_123',
      processor_plan: 'price_123',
      status: 'canceled'
    )

    # Test the scope without mocking
    active_subscriptions = @user.active_subscriptions
    assert_includes active_subscriptions, active_sub
    refute_includes active_subscriptions, canceled_sub

    # Verify STI types
    assert_instance_of Pay::Stripe::Subscription, active_sub
    assert_instance_of Pay::Stripe::Subscription, canceled_sub
  end

  test 'Pay Charge creation and querying works with STI' do
    pay_customer = Pay::Stripe::Customer.create!(
      owner: @user,
      processor: 'stripe',
      processor_id: 'cus_charge_test_123'
    )

    charge = Pay::Stripe::Charge.create!(
      customer: pay_customer,
      processor_id: 'ch_test_123',
      amount: 1000,
      currency: 'usd'
    )

    # Verify STI type
    assert_instance_of Pay::Stripe::Charge, charge
    assert_equal 'Pay::Stripe::Charge', charge.type

    # Test querying charges
    customer_charges = pay_customer.charges
    assert_includes customer_charges, charge

    # Verify the relationship returns correct STI type
    assert_instance_of Pay::Stripe::Charge, customer_charges.first
  end

  test 'Pay gem scopes and queries work correctly' do
    # This will test that Pay gem internal queries work with STI
    pay_customer = Pay::Stripe::Customer.create!(
      owner: @user,
      processor: 'stripe',
      processor_id: 'cus_scope_test_123'
    )

    # Use Pay gem's own methods that rely on STI
    stripe_customers = Pay::Stripe::Customer.stripe
    assert_includes stripe_customers, pay_customer

    # Each returned customer should be the correct STI type
    stripe_customers.each do |customer|
      assert_instance_of Pay::Stripe::Customer, customer
    end
  end

  test 'polymorphic associations work with Pay gem STI' do
    pay_customer = Pay::Stripe::Customer.create!(
      owner: @user,
      processor: 'stripe',
      processor_id: 'cus_poly_test_123'
    )

    subscription = Pay::Stripe::Subscription.create!(
      customer: pay_customer,
      name: 'default',
      processor_id: 'sub_poly_test_123',
      processor_plan: 'price_123',
      status: 'active'
    )

    charge = Pay::Stripe::Charge.create!(
      customer: pay_customer,
      subscription: subscription,
      processor_id: 'ch_poly_test_123',
      amount: 1000,
      currency: 'usd'
    )

    # Test polymorphic relationships work correctly with STI
    assert_equal pay_customer, subscription.customer
    assert_equal pay_customer, charge.customer
    assert_equal subscription, charge.subscription

    # Verify all are correct STI types
    assert_instance_of Pay::Stripe::Customer, subscription.customer
    assert_instance_of Pay::Stripe::Customer, charge.customer
    assert_instance_of Pay::Stripe::Subscription, charge.subscription
  end

  test 'User.with_subscriptions_active scope works with real Pay data' do
    # Test the actual scope that depends on Pay gem queries
    pay_customer = Pay::Stripe::Customer.create!(
      owner: @user,
      processor: 'stripe',
      processor_id: 'cus_user_scope_123',
      default: true
    )

    subscription = Pay::Stripe::Subscription.create!(
      customer: pay_customer,
      name: 'default',
      processor_id: 'sub_user_scope_123',
      processor_plan: 'price_123',
      status: 'active'
    )

    # This scope joins with pay_subscriptions table and filters by status
    users_with_active_subs = User.with_subscriptions_active
    assert_includes users_with_active_subs, @user

    # Cancel subscription and verify scope excludes user
    subscription.update!(status: 'canceled')
    users_with_active_subs_after_cancel = User.with_subscriptions_active
    refute_includes users_with_active_subs_after_cancel, @user
  end
end
