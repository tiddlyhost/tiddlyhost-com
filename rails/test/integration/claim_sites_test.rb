require 'test_helper'
require 'minitest/mock'

class ClaimSitesTest < CapybaraIntegrationTest

  setup do
    sign_in users(:bobby)
  end

  test "link is present" do
    visit '/sites'
    click_link "Claim Tiddlyspot site"
    assert_selector "h1", text: "Claim ownership"
  end

  def non_existing
    mock_helper do |m|
      m.expect(:exists?, false)
    end
  end

  def existing
    mock_helper do |m|
      m.expect(:exists?, true)
      m.expect(:is_private?, false)
      m.expect(:htpasswd_file, 'mulder:muG/6sge3L4Sc')
    end
  end

  def with_mocked_site(mock, &blk)
    TspotFetcher.stub(:new, mock, &blk)
  end

  def attempt_claim(site_name, password, mocked_site, expected_text)
    visit '/tspot_sites/claim_form'
    fill_in :site_name, with: site_name
    fill_in :password, with: password
    with_mocked_site(mocked_site) do
      click_button 'Claim'
    end
    assert_selector 'h1', text: expected_text
  end

  test "non-existent" do
    attempt_claim('simon', 'xx', non_existing, "does not exist")
  end

  test "incorrect password" do
    attempt_claim('simon', 'xx', existing, 'Claim unsuccessful')
  end

  test "already owned" do
    TspotSite.find_by_name('mysite').update!(user: users(:mary))
    attempt_claim('mysite', 'xx', existing, 'owned by someone else')
  end

  test "success" do
    assert_difference("TspotSite.count") do
      attempt_claim('mulder', 'trustno1', existing, "claimed successfully")
    end
    site = TspotSite.last
    assert_equal 'mulder', site.name
    assert_equal users(:bobby), site.user
  end

  test "disowning" do
    # User bobby owns a site
    site = TspotSite.find_by_name('mysite')
    site.update!(user: users(:bobby))

    # Confirm it's visible
    visit '/sites'
    assert_selector '.sitelink a', text: 'mysite.tiddlyspot-example.com'

    # Disown it
    click_on "Disown"
    assert_current_path '/sites'

    # Confirm it's no longer visible# and it was really disowned
    assert_selector '.sitelink a', text: 'mysite.tiddlyspot-example.com', count: 0
    assert_nil site.reload.user
  end

end
