
module Settings::Features
  module_function

  def admin_enabled?(user)
    user&.is_admin?
  end

  def site_history_enabled?(user)
    user&.is_admin? || user&.subscribed?
  end

  def subscriptions_enabled?(user=nil)
    # Hide subscriptions from non-admins until they're ready to launch
    user&.is_admin?
  end

  def redirect_tspot_to_url_enabled?(user)
    user&.is_admin? || user&.subscribed?
  end

end
