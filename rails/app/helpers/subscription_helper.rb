
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

  def subscription_renews_info(subscription)
    if !subscription&.status == "active"
      "inactive"
    elsif subscription.ends_at
      "ends in #{subscription_when(subscription.ends_at)}"
    else
      "renews in #{subscription_when(subscription.current_period_end)}"
    end
  end

  def subscription_renew_text(subscription)
    if subscription.ends_at.present?
      "Your subscription ends in #{subscription_when(subscription.ends_at)}."
    else
      "Your next payment is in #{subscription_when(subscription.current_period_end)}."
    end
  end

  def subscription_when(ts)
    distance_of_time_in_words(Date.today, ts.to_date)
  end

end
