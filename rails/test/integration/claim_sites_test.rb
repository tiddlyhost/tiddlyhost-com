require 'test_helper'
require 'minitest/mock'

class ClaimSitesTest < CapybaraIntegrationTest
  setup do
    sign_in users(:bobby)

    @site = TspotSite.find_by_name('mysite')
    # Make sure it has a blob, otherwise it's considered to not really exist
    # Fixme: Make it so the fixture data has a blob already I guess..?
    @site.content_upload('dummy content')
  end

  test 'link is present' do
    visit '/sites'
    click_link 'Claim Tiddlyspot site'
    assert_selector 'h2', text: 'Claim Tiddlyspot site'
  end

  # Fetcher functionality has been removed since the S3 bucket is gone.
  # Sites can no longer be destubbed from external sources.

  def attempt_claim(site_name, password, expected_text)
    visit '/tspot_sites/claim_form'
    fill_in :site_name, with: site_name
    fill_in :password, with: password
    click_button 'Claim'
    assert_selector 'h1', text: expected_text
  end

  test 'non-existent' do
    attempt_claim('zimon', 'xx', 'does not exist')
  end

  test 'already owned' do
    @site.update!(user: users(:mary))
    attempt_claim('mysite', 'xx', 'owned by someone else')
  end

  test 'successful claim' do
    attempt_claim('mysite', 'abc123', 'claimed successfully')
    assert_equal 'mysite', @site.name
    assert_equal users(:bobby), @site.reload.user
  end

  test 'disowning' do
    # User bobby owns a site
    @site.update!(user: users(:bobby))

    # Confirm it's visible
    visit '/sites'
    assert_selector '.sitelink a[href="http://mysite.tiddlyspot-test-example.com"]', text: 'mysite'

    # Disown it
    click_on 'Disown'
    assert_current_path '/sites'

    # Confirm it's no longer visible and it was really disowned
    assert_selector '.sitelink a', text: 'mysite.tiddlyspot-test-example.com', count: 0
    assert_nil @site.reload.user
  end

  test 'delete' do
    # User bobby owns a site
    @site.update!(user: users(:bobby))

    # Make it so there's only one delete link for convenience
    Site.find_by_name('mysite').update(user: users(:mary))

    # Confirm it's visible
    visit '/sites'
    assert_selector '.sitelink a[href="http://mysite.tiddlyspot-test-example.com"]', text: 'mysite'

    # Delete it
    click_on 'Delete'
    assert_current_path '/sites'

    # Confirm it's no longer visible and it was really deleted
    assert_selector '.sitelink a', text: 'mysite.tiddlyspot-test-example.com', count: 0
    assert @site.reload.deleted?
  end
end
