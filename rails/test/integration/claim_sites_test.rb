require 'test_helper'
require 'minitest/mock'

class ClaimSitesTest < CapybaraIntegrationTest

  setup do
    sign_in users(:bobby)
  end

  test "link is present" do
    visit '/sites'
    click_link "Claim Tiddlyspot site"
    assert_selector "h2", text: "Claim Tiddlyspot site"
  end

  def mocked_fetcher
    mock_helper do |m|
      m.expect(:is_private?, false)
      m.expect(:htpasswd_file, 'mulder:muG/6sge3L4Sc')
      m.expect(:html_file, 'whatever')
    end
  end

  def with_mocked_site(mock, &blk)
    TspotFetcher.stub(:new, mock, &blk)
  end

  def attempt_claim(site_name, password, mocked_site, expected_text)
    visit '/tspot_sites/claim_form'
    fill_in :site_name, with: site_name
    fill_in :password, with: password
    if mocked_site
      site = TspotSite.find_by_name(site_name)

      # The others are stubs but this one is not..
      assert site.is_stub? unless site_name == 'mysite'

      mocked_site.expect(:name, site_name)
      with_mocked_site(mocked_site) do
        click_button 'Claim'
      end

      refute site.reload.is_stub?

    else
      click_button 'Claim'

    end
    assert_selector 'h1', text: expected_text

    assert_mock mocked_site if mocked_site
  end

  test "non-existent" do
    attempt_claim('zimon', 'xx', nil, "does not exist")
  end

  test "incorrect password" do
    attempt_claim('simon', 'xx', mocked_fetcher, 'Claim unsuccessful')
  end

  test "already owned" do
    TspotSite.find_by_name('mysite').update!(user: users(:mary))
    attempt_claim('mysite', 'xx', nil, 'owned by someone else')
  end

  test "success" do
    site = TspotSite.find_by_name('mulder')
    assert site.is_stub?
    attempt_claim('mulder', 'trustno1', mocked_fetcher, "claimed successfully")
    refute site.reload.is_stub?
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
