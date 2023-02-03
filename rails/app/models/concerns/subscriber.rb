
module Subscriber
  extend ActiveSupport::Concern

  included do
    # Set up methods provided by the pay gem
    pay_customer

    # For convenience
    delegate :subscription, :subscribed?, :checkout, :billing_portal,
      to: :payment_processor, allow_nil: true

    scope :with_subscriptions, -> {
      left_joins(:payment_processor).
        left_joins(:subscriptions).
        # Fixme: This condition should really be in the subscriptions left join,
        # but that requires using raw sql to define the join iiuc
        where("pay_subscriptions.status IS NULL OR pay_subscriptions.status = 'active'")
    }

    # Uncomment to help test UI for unsubcribed user
    #def subscribed?; false; end
  end

  def checkout_session_for(plan, frequency=:monthly)
    price_id = Settings.stripe_product(plan, frequency)&.id
    raise "Can't find price id for #{plan.inspect}, #{frequency.inspect}!" unless price_id
    checkout_session_for_price_id(price_id)
  end

  def checkout_session_for_price_id(price_id)
    self.payment_processor.checkout(
      mode: "subscription",
      line_items: price_id,
      success_url: "#{Settings.main_site_url}/subscription",
      cancel_url: "#{Settings.main_site_url}/subscription"
    )
  end

  def subscription_info
    if subscribed?
      Settings.stripe_product_by_id(subscription.processor_plan)
    else
      Settings.stripe_product(:free)
    end
  end

  # Users should not have more than one active subscription but
  # there's no active prevention of that currently in stripe iiuc.
  # Might need an upgrade/downgrade button in the future, see
  # https://stripe.com/docs/billing/subscriptions/upgrade-downgrade
  # In the short term this might help detect if any user somehow
  # has multiple subscriptions.
  # (This method is not used currently.)
  #
  def active_subscriptions
    subscriptions.where(status: "active")
  end

  # In practice we're expecting only stripe and only one pay customer
  # record per user but in theory there could be multiple I guess.
  # (This method is not used currently.)
  #
  def pay_customer_stripe
    pay_customers.where(processor: :stripe).first
  end

end
