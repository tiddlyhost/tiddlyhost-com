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

  def subscriptions_enabled?(_user = nil)
    true
  end

  def custom_domains_enabled?(user)
    # While we're working on this feature I want to hide it
    # from regular users.
    user&.is_admin? || Rails.env.test?
  end

  def redirect_tspot_to_url_enabled?(user)
    user&.is_admin? || user&.has_subscription?
  end
end
