module HomeHelper

  def paypal_donate_button_id
    Rails.application.credentials.dig(:paypal, :donate_button_id)
  end

end
