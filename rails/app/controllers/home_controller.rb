class HomeController < ApplicationController
  def index
    if user_signed_in?
      redirect_to sites_path
    end
  end

  def after_registration
    render template: 'devise/registrations/after_registration'
  end

  def about
    @build_info = {
      'version' => App::VERSION,
      'empties' => Empty.versions,
      'short_sha' => Settings.short_sha(9),
    }.merge(Settings.build_info)
  end

  def donate
  end

  def support
  end

  def privacy_policy
  end

  def terms_of_use
  end

  def favicon
    send_favicon('favicon.ico')
  end

  def error_404
    render_error_page(404, 'Not Found')
  end

  def error_422
    render_error_page(422, 'Unprocessable Entity')
  end

  def error_500
    render_error_page(500, 'Internal Server Error')
  end

  # This persists the theme mode preference. There is some javascript to handle
  # changing it in the browser. We're counting on the behavior of helpers.next_theme_mode
  # being the same as what is happening in javascript, otherwise it will get out of sync.
  # See also setLightDark in app/javascript/packs/application.js, and
  # $('.mode-cycle-btn').on('click', ...
  def mode_cycle
    new_theme_mode = helpers.next_theme_mode
    cookies[:theme_mode] = new_theme_mode
    current_user.theme_mode_pref = new_theme_mode if current_user
    head 200
  end

  private

  def render_error_page(status_code, status_message)
    respond_to do |format|
      format.html do
        @status_code = status_code
        @status_message = status_message
        render :error_page, status: status_code, layout: 'simple'
      end

      format.text do
        render plain: "#{status_code} #{status_message}", status: status_code
      end

      format.json do
        render json: { error: "#{status_code} #{status_message}" }, status: status_code
      end

      format.all do
        head status_code
      end
    end
  end
end
