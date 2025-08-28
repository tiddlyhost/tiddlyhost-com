module ThemeModeHelper
  MODES = %w[auto light dark]

  DEFAULT_MODE = MODES.first

  TITLES = {
    "auto" => "Auto",
    "light" => "Light",
    "dark" => "Dark",
  }

  ICONS = {
    "auto" => "circle-half",
    "light" => "sun",
    "dark" => "moon-stars",
  }

  def theme_mode(mode = nil)
    mode ||= current_user&.theme_mode_pref
    mode ||= cookies[:theme_mode]
    return mode if mode.in? MODES

    DEFAULT_MODE
  end

  def next_theme_mode(mode = nil)
    CycleHelper.cycle_next(theme_mode(mode), MODES)
  end

  def theme_title(cookie_value = nil)
    TITLES[theme_mode(cookie_value)]
  end

  def theme_icon(cookie_value = nil)
    ICONS[theme_mode(cookie_value)]
  end

  def _theme_mode_cycle_link(theme, screen_size)
    link_icon = theme_icon(theme.to_s)
    link_text = theme_title(theme.to_s)

    # screen size :small is for when the burger menu is showing, e.g. on a phone
    link_content = screen_size == :small ? safe_join([bi_icon(link_icon), link_text]) : bi_icon(link_icon)
    screen_size_class = screen_size == :small ? 'd-block d-sm-none' : 'd-none d-sm-block'

    nav_link_to(link_content, home_mode_cycle_path, remote: true, title: link_text,
      li_class: "#{screen_size_class} #{link_icon}-btn mode-cycle-btn")
  end

  # See $('.mode-cycle-btn').on('click', ...) in app/javascript/packs/application.js
  # which attaches some behavior to these buttons. See also HomeController#mode_cycle
  def theme_mode_cycle_link
    # We render six buttons but only one of them will be visible at a time
    safe_join([
      _theme_mode_cycle_link(:auto, :big),
      _theme_mode_cycle_link(:light, :big),
      _theme_mode_cycle_link(:dark, :big),
      _theme_mode_cycle_link(:auto, :small),
      _theme_mode_cycle_link(:light, :small),
      _theme_mode_cycle_link(:dark, :small),
    ])
  end
end
