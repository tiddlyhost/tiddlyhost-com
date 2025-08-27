require 'test_helper'

class UserTest < ActiveSupport::TestCase
  setup do
    @user = users(:bobby)
  end

  test 'user types' do
    assert_equal 'basic', @user.user_type.name
  end

  test 'username uniqueness' do
    User.create!(
      email: 'bob@gmail.com', name: 'Another Bob', username: 'Bob', password: 'Abcd1234')

    [
      'bob',
      'Bob',
      'BOB',

    ].each do |disallowed_username|
      @user.username = disallowed_username
      refute @user.valid?
      assert_match(/has already been taken/, @user.errors.full_messages.first)
    end
  end

  test 'username validation' do
    [
      # No leading or trailing dashes
      '-bob-',
      '-bob',
      'bob-',
      # No spaces or other chars
      'bob bobby',
      'bob$',
      'bob_bobby',
      # No Double dashes
      'bo--b',
      # Too short
      'bb',
      # Too long
      'b' * 31,

    ].each do |disallowed_username|
      @user.username = disallowed_username
      refute @user.valid?
      assert_match(/is not allowed|is too short|is too long/, @user.errors.full_messages.first)
    end

    [
      'bob',
      'bob-tables',
      'Bob ',
      'BOB',
      # Max length
      'b' * 30,
      # Blank is allowed
      '',
      ' ',

    ].each do |allowed_username|
      @user.username = allowed_username
      assert @user.valid?
      assert @user.save
      # Case is preserved, trailing space is stripped
      assert_equal allowed_username.strip, @user.reload.username
    end
  end

  test 'user preferences' do
    assert_equal 'list', @user.list_mode_pref
    @user.list_mode_pref = 'grid'
    assert_equal 'grid', @user.reload.list_mode_pref
    assert_raises(ArgumentError) { @user.list_mode_pref = 'carousel' }

    assert_equal 'auto', @user.theme_mode_pref
    @user.theme_mode_pref = 'dark'
    assert_equal 'dark', @user.reload.theme_mode_pref
    assert_raises(ArgumentError) { @user.theme_mode_pref = 'purple' }
  end
end
