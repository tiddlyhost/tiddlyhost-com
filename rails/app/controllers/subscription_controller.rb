
class SubscriptionController < ApplicationController
  before_action :authenticate_user!, except: :pricing
  before_action -> { require_feature_enabled!(:subscriptions) }

  before_action :set_user_vars

  def show
  end

  def plans
  end

  def pricing
    render :plans
  end

  private

  def set_user_vars
    if @user = current_user
      # Needed because we generate a working checkout link
      @user.set_payment_processor(:stripe)

      @portal_session = @user.billing_portal
      @subscribed = @user.subscribed?
      @subscription = @user.subscription
      @subscription_info = @user.subscription_info
    end
  end

end
