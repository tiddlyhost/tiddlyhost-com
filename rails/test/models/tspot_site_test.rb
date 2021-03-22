require "test_helper"

class TspotSiteTest < ActiveSupport::TestCase

  setup do
    @site = TspotSite.find_by_name('mysite')
  end

  test "url" do
    assert_equal 'http://mysite.tiddlyspot-example.com', @site.url
    assert_equal 'http://tiddlyspot-example.com', Settings.tiddlyspot_url
  end

end
