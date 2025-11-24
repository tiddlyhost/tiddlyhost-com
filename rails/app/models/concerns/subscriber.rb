module Subscriber
  extend ActiveSupport::Concern

  included do
    # Set up methods provided by the pay gem
    pay_customer

    # For convenience
    delegate :subscription, :subscribed?, :checkout, :billing_portal,
      to: :payment_processor, allow_nil: true

    # Could possibly return multiple rows per user
    scope :join_subscriptions, lambda {
      left_joins(:payment_processor).left_joins(:pay_subscriptions)
    }

    # The distinct is because this is used to count users
    scope :with_subscriptions_active, lambda {
      join_subscriptions.where(pay_subscriptions: { status: 'active' }).select('distinct users.id')
    }

    # Uncomment to help test UI for unsubcribed user
    #def subscribed?; false; end
  end

  def checkout_session_for(plan, frequency = :monthly)
    price_id = Settings.stripe_product(plan, frequency)&.id
    raise "Can't find price id for #{plan.inspect}, #{frequency.inspect}!" unless price_id

    checkout_session_for_price_id(price_id)
  end

  def checkout_session_for_price_id(price_id)
    self.payment_processor.checkout(
      mode: 'subscription',
      line_items: price_id,
      success_url: "#{Settings.main_site_url}/subscription/success",
      cancel_url: "#{Settings.main_site_url}/subscription"
    )
  end

  def subscription_info
    if subscribed?
      if subscription&.processor_plan
        Settings.stripe_product_by_id(subscription.processor_plan)
      else
        # Workaround/hack for this error:
        #   undefined method `processor_plan' for nil:NilClass
        #   app/models/concerns/subscriber.rb:44:in `subscription_info'
        # Not sure how it could happen, but maybe the processor_plan
        # record didn't get updated yet even though subscribed? return
        # true somehow. This is a hack but it's likely to work since
        # there's only one product currently.
        Settings.stripe_product(:standard)
      end
    elsif alt_subscription?
      Settings.stripe_product(alt_subscription.to_sym).presence || Settings.stripe_product(:free)
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
    pay_subscriptions.where(status: 'active')
  end

  # In practice we're expecting only stripe and only one pay customer
  # record per user but in theory there could be multiple I guess.
  # (This method is not used currently.)
  #
  def pay_customer_stripe
    pay_customers.where(processor: :stripe).first
  end

  # Beware potential confusion when using this method since it may
  # not be a real stripe subscription.
  def has_subscription?
    subscribed? || alt_subscription.present?
  end
end
