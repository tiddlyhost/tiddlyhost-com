require "test_helper"

class TspotSiteTest < ActiveSupport::TestCase

  setup do
    @site_name = 'mysite'
    @site = TspotSite.find_by_name(@site_name)
    @old_passwd, @new_passwd, @new_new_passwd = 'abc123', 'xyz789', 'foobar7'
  end

  test "url" do
    assert_equal 'mysite.tiddlyspot-example.com', @site.host
    assert_equal 'http://mysite.tiddlyspot-example.com', @site.url
    assert_equal 'http://tiddlyspot-example.com', Settings.tiddlyspot_url
  end

  test "is_stub" do
    refute @site.is_stub?

    stub_site = TspotSite.create(name: 'stubby')
    assert stub_site.is_stub?
  end

  def assert_legacy_password(passwd=@old_passwd)
    assert_nil @site.password_digest
    assert @site.use_legacy_password?
    assert @site.passwd_ok?(@site_name, passwd)
  end

  def assert_new_password(passwd=@new_passwd)
    assert_equal 60, @site.password_digest.length
    refute @site.use_legacy_password?
    assert @site.passwd_ok?(@site_name, passwd)
  end

  test "setting a new password" do
    # Initially the legacy password works
    assert_legacy_password

    # Try setting a too short password
    e = assert_raises(ActiveRecord::RecordInvalid) { @site.set_password('xyz', 'xyz') }
    assert_includes e.message, "too short"

    # Legacy password still works
    assert_legacy_password

    # Try to set password with a bad confirmation
    e = assert_raises(ActiveRecord::RecordInvalid) { @site.set_password(@new_passwd, 'xyz') }
    assert_includes e.message, "doesn't match"

    # Legacy password still works
    assert_legacy_password

    # Try to set a blank password
    e = assert_raises(ActiveRecord::RecordInvalid) { @site.set_password('', '') }
    assert_includes e.message, "doesn't match" # not sure why we get this message...

    # Legacy password still works
    assert_legacy_password

    # Set a new password correctly
    @site.set_password(@new_passwd, @new_passwd)

    # old password no longer works
    refute @site.passwd_ok?('mysite', @old_passwd)

    # New password does work
    assert_new_password

    # Set a new password incorrectly again
    assert_raises{ @site.set_password(@new_new_passwd, 'xyz') }

    # New password still works
    assert_new_password

    # Set a new password correctly again
    @site.set_password(@new_new_passwd, @new_new_passwd)

    # The newer new password now works
    assert_new_password(@new_new_passwd)

    # Previous passwords don't work
    refute @site.passwd_ok?('mysite', @new_passwd)
    refute @site.passwd_ok?('mysite', @old_passwd)

  end

  # See also test/controllers/tiddlyspot_controller_test
end
