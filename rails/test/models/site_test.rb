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
end
