require "test_helper"

class SiteTest < ActiveSupport::TestCase

  setup do
    @site = Site.find_by_name('mysite')
  end

  test "url" do
    assert_equal 'http://mysite.example.com', @site.url
    assert_equal 'http://example.com', Settings.main_site_url
  end

  test "name validation" do

    # These names are invalid
    [
      "-aaa",
      "aaa-",
      "-aaa-",
      "a--a",
      "Aaa",
      "aa",
      "abc$",
      "x" * 64,
      "ftp",
      "www",
      "wiki",
      "foo\nbar",
      "foo\tbar",
      "foo bar",
    ].each do |invalid_name|
      @site.update(name: invalid_name)
      refute @site.valid?, "#{invalid_name} unexpectedly allowed!"
    end

    # These names are valid
    [
      "aaa",
      "aa-aa",
      "bbb-cc-dd",
      "x" * 63,
      "ab9",
      "777",
      "123-aaa",
      "myftp",
      "shit", # Hmm...
    ].each do |valid_name|
      @site.update(name: valid_name)
      assert @site.valid?, "#{valid_name} unexpectedly disallowed!"
    end

  end

  test "view counts and timestamps" do
    orig_updated_at = @site.updated_at.to_i
    orig_accessed_at = @site.accessed_at.to_i
    orig_view_count = @site.view_count
    orig_access_count = @site.access_count

    @site.touch_accessed_at
    # The accessed_at field is touched
    assert_operator orig_accessed_at, :<, @site.accessed_at.to_i
    # The updated_at field is not
    assert_equal orig_updated_at, @site.updated_at.to_i

    @site.increment_view_count
    @site.increment_access_count
    # The counters were incremented
    assert_equal orig_view_count + 1, @site.reload.view_count
    assert_equal orig_access_count + 1, @site.reload.access_count
    # The updated_at field is untouched
    assert_equal orig_updated_at, @site.updated_at.to_i
  end

end
