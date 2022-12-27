
module Settings::Features
  module_function

  def admin_enabled?(user)
    user&.is_admin?
  end

  def site_history_enabled?(user)
    # Later: users with a subscription
    user&.is_admin?
  end

  def redirect_tspot_to_url_enabled?(user)
    # Later: users with a subscription
    user&.is_admin?
  end

end
