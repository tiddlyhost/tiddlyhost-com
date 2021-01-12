require "test_helper"

class SiteTest < ActiveSupport::TestCase

  test "url" do
    site = sites(:mysite)

    assert_equal 'http://mysite.example.com', site.url
  end
end
