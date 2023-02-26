
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
      "ends in #{distance_of_time_in_words(Date.today, subscription.ends_at.to_date)}"
    else
      "renews in #{distance_of_time_in_words(Date.today, subscription.current_period_end.to_date)}"
    end
  end

end
