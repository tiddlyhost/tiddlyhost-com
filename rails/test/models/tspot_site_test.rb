require "test_helper"

class TspotSiteTest < ActiveSupport::TestCase

  setup do
    @site = TspotSite.find_by_name('mysite')
  end

  test "url" do
    assert_equal 'http://mysite.tiddlyspot-example.com', @site.url
    assert_equal 'http://tiddlyspot-example.com', Settings.tiddlyspot_url
  end

  test "is_stub" do
    refute @site.is_stub?

    stub_site = TspotSite.create(name: 'stubby')
    assert stub_site.is_stub?
  end

  # See also test/controllers/tiddlyspot_controller_test
end
