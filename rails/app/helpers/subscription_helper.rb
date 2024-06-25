# frozen_string_literal: true

module SubscriptionHelper

  def feature_descriptions_for(plan)
    feature_list = case plan
    when :free
      [plan]
    when :standard
      [:free, plan]
    when :premium
      [:free, :standard, plan]
    end

    feature_list.map{ |p| Settings.plan_descriptions.dig(p, :features) || [] }.flatten
  end

  def stripe_customer_url(user)
    stripe_dashboard_url("customers", user.pay_customer_stripe.processor_id)
  end

  def stripe_dashboard_url(*path)
    [
      "https://dashboard.stripe.com",
      ("test" unless Rails.env.production?),
      *path
    ].compact.join("/")
  end

  # Shown to admin
  def subscription_renews_info(subscription)
    if subscription.status == "active"
      if subscription.ends_at.present?
        "ends in #{subscription_when(subscription.ends_at)}"
      elsif subscription.current_period_end.present?
        "renews in #{subscription_when(subscription.current_period_end)}"
      else
        # Not sure if this is possible
        "active"
      end
    else
      subscription.status
    end
  end

  # Shown to admin
  def plan_name_with_indicator(user)
    plan_name = user.subscription_info.name

    # Show asterix if they were once subscribed
    indicator = "*" if plan_name == "Free" && user.subscriptions.any?

    # Show if they have an alternative payment method subscription
    indicator = " (alt)" if user.alt_subscription.present?

    "#{plan_name}#{indicator}"
  end

  # Shown to users
  def subscription_renew_text(subscription)
    if subscription.ends_at.present?
      "Your subscription ends in #{subscription_when(subscription.ends_at)}."
    elsif subscription.current_period_end.present?
      "Your next payment is in #{subscription_when(subscription.current_period_end)}."
    else
      # Not sure if this is possible
      ""
    end
  end

  def subscription_when(ts)
    distance_of_time_in_words(Date.today, ts.to_date)
  end

end
