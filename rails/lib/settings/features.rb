
module Settings::Features
  module_function

  def admin_enabled?(user=nil)
    user&.is_admin?
  end

  def site_history_enabled?(user=nil)
    # Later: users with a subscription
    user&.is_admin?
  end

end
