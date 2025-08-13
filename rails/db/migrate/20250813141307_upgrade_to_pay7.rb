class UpgradeToPay7 < ActiveRecord::Migration[7.2]
  def up
    add_column :pay_subscriptions, :payment_method_id, :string
    add_column :pay_customers, :stripe_account, :string
    add_column :pay_subscriptions, :stripe_account, :string
    add_column :pay_payment_methods, :stripe_account, :string
    add_column :pay_charges, :stripe_account, :string

    Pay::Customer.find_each { |c| c.update(stripe_account: c.data&.dig("stripe_account")) }
    Pay::Subscription.find_each { |c| c.update(stripe_account: c.data&.dig("stripe_account")) }
    Pay::PaymentMethod.find_each { |c| c.update(stripe_account: c.data&.dig("stripe_account")) }
    Pay::Charge.find_each { |c| c.update(stripe_account: c.data&.dig("stripe_account")) }
  end

  def down
    remove_column :pay_subscriptions, :payment_method_id
    remove_column :pay_customers, :stripe_account
    remove_column :pay_subscriptions, :stripe_account
    remove_column :pay_payment_methods, :stripe_account
    remove_column :pay_charges, :stripe_account
  end
end
