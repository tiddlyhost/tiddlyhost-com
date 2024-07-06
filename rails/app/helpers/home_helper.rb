# frozen_string_literal: true

module HomeHelper
  def paypal_donate_button_id
    Settings.secrets(:paypal, :donate_button_id)
  end
end
