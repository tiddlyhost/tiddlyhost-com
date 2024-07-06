# frozen_string_literal: true

require 'test_helper'

class SettingsTest < ActiveSupport::TestCase
  test 'feature enabled' do
    admin_user = User.find_by_id(1)
    admin_user.update(user_type: UserType.superuser)
    assert admin_user.is_admin?

    non_admin_user = User.find_by_id(2)
    refute non_admin_user.is_admin?

    # Can't stub a non-existing method so do it like this
    Settings::Features.module_eval do
      def self.foo_enabled?(_user) = true
      def self.bar_enabled?(user) = user
      def self.baz_enabled?(user) = user&.is_admin?
      def self.quux_enabled?(_user) = false
    end

    {
      nil => [true, false, false, false, false],
      non_admin_user => [true, true, false, false, false],
      admin_user => [true, true, true, false, true],

    }.each do |user, expected|
      actual = %i[foo bar baz quux site_history].map { |f| Settings.feature_enabled?(f, user) }
      assert_equal(expected, actual)
    end
  end

  def with_mocked_grant_feature_data(user_list, &)
    stubbed = lambda do |*args|
      assert_equal args, [:grant_feature, :foo_bar]
      user_list
    end

    Settings.stub(:secrets, stubbed, &)
  end

  test 'manually granted feature access' do
    {
      ['bobby@tables.com'] => true,
      ['mary@tables.com'] => false,
      [1] => true,
      [2] => false,
      [] => false,
      nil => false,

    }.each do |user_list, expected|
      with_mocked_grant_feature_data(user_list) do
        assert_equal(
          expected,
          Settings.feature_enabled?(:foo_bar, users(:bobby)),
          "Unexpected result for #{user_list.inspect}")
      end
    end
  end
end
