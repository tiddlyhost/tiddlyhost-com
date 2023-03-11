
class SubscriptionController < ApplicationController
  before_action :authenticate_user!
  before_action -> { require_feature_enabled!(:subscriptions) }

  before_action :set_user_vars

  def show
  end

  def plans
  end

  private

  def set_user_vars
    @user = current_user

    # Needed because we generate a working checkout link
    @user.set_payment_processor(:stripe)

    @portal_session = @user.billing_portal
    @subscribed = @user.subscribed?
    @subscription = @user.subscription
    @subscription_info = @user.subscription_info
  end

end
