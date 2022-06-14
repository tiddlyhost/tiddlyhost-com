require "test_helper"

class SettingsTest < ActiveSupport::TestCase

  test "feature enabled" do
    admin_user = User.find_by_id(1)
    admin_user.update(plan: Plan.find_by_name('superuser'))
    assert admin_user.is_admin?

    non_admin_user = User.find_by_id(2)
    refute non_admin_user.is_admin?

    # Can't stub a non-existing method so do it like this
    Settings::Features.module_eval do
      def self.foo_enabled?(user); true; end
      def self.bar_enabled?(user); user; end
      def self.baz_enabled?(user); user&.is_admin?; end
      def self.quux_enabled?(user); false; end
    end

    {
      nil => [true, false, false, false],
      non_admin_user => [true, true, false, false],
      admin_user => [true, true, true, false],

    }.each do |user, expected|
      actual = %i[foo bar baz quux].map{ |f| Settings.feature_enabled?(f, user) }
      assert_equal(expected, actual)
    end

  end

end
