
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

end
