require "test_helper"

class SitesTest < CapybaraIntegrationTest
  setup do
    sign_in users(:bobby)
  end

  test "visiting the index" do
    visit sites_url
    assert_selector "h1", text: "Your sites"
  end

  test "creating a Site" do
    visit sites_url
    click_on "Create site"

    fill_in "site_name", with: "bar"
    click_on "Create"

    # Back to the sites index after create
    assert page.has_css? "a", text: "bar.example.com"
  end

  test "updating a Site" do
    visit sites_url
    click_on "Settings", match: :first

    fill_in "Name", with: "foo"
    click_on "Update"

    # Back to the sites index after update
    assert page.has_css? "a", text: "foo.example.com"
  end

end
