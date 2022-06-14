
module Settings::Features
  module_function

  def admin_enabled?(user=nil)
    user&.is_admin?
  end

end
