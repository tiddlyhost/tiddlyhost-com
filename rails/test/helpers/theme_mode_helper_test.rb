require 'test_helper'

class ThemeModeHelperTest < ActionView::TestCase
  def setup
    # Mock cookies and current_user for helper methods
    @cookies = {}
    define_singleton_method(:cookies) { @cookies }

    @user = nil
    define_singleton_method(:current_user) { @user }
  end

  test "theme mode" do
    {
      nil => ["auto", "light"],
      "garbage" => ["auto", "light"],
      "auto" => ["auto", "light"],
      "light" => ["light", "dark"],
      "dark" => ["dark", "auto"],
    }.each do |cookie_value, (expected, expected_next)|
      assert_equal expected, theme_mode(cookie_value), "current value"
      assert_equal expected_next, next_theme_mode(cookie_value), "next value"
      assert theme_title(cookie_value).present?
    end
  end

  test "theme mode with logged in user preferences" do
    # Create a mock user with theme preferences
    user = Object.new
    user.define_singleton_method(:theme_mode_pref) { @theme_mode_pref }
    user.define_singleton_method(:theme_mode_pref=) { |value| @theme_mode_pref = value }

    # Set the mock user as current_user
    @user = user

    # Test: User preference takes priority over cookie
    @cookies[:theme_mode] = "light"
    user.theme_mode_pref = "dark"
    assert_equal "dark", theme_mode, "user preference should override cookie"
    assert_equal "auto", next_theme_mode, "next mode should cycle from user preference"

    # Test: User preference with nil cookie
    @cookies[:theme_mode] = nil
    user.theme_mode_pref = "light"
    assert_equal "light", theme_mode, "user preference should work with nil cookie"
    assert_equal "dark", next_theme_mode, "next mode should cycle from user preference"

    # Test: Invalid user preference falls back to cookie
    user.theme_mode_pref = "invalid"
    @cookies[:theme_mode] = "auto"
    assert_equal "auto", theme_mode, "should fall back to cookie with invalid user pref"

    # Test: No user preference, use cookie
    user.theme_mode_pref = nil
    @cookies[:theme_mode] = "dark"
    assert_equal "dark", theme_mode, "should use cookie when no user preference"

    # Test: No user preference, no cookie
    @cookies[:theme_mode] = nil
    user.theme_mode_pref = nil
    assert_equal "auto", theme_mode, "should fall back to default"

    # Test: Theme titles and icons work with user preferences
    user.theme_mode_pref = "dark"
    assert_equal "Dark", theme_title, "theme title should work with user preference"
    assert_equal "moon-stars", theme_icon, "theme icon should work with user preference"
  end
end
