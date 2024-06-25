# frozen_string_literal: true

module Settings::Features
  module_function

  def admin_enabled?(user)
    user&.is_admin?
  end

  def site_history_enabled?(user)
    user&.is_admin? || user&.has_subscription?
  end

  def site_history_preview_enabled?(user)
    subscriptions_enabled?(user) && !site_history_enabled?(user)
  end

  def subscriptions_enabled?(user=nil)
    true
  end

  def redirect_tspot_to_url_enabled?(user)
    user&.is_admin? || user&.has_subscription?
  end

end
