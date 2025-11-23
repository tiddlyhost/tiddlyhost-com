require 'test_helper'

class TiddlyspotControllerTest < ActionDispatch::IntegrationTest
  test 'home page' do
    host! Settings.tiddlyspot_host
    get '/'
    assert_response :success
    assert_select 'a.btn', 'Continue to Tiddlyhost', response.body
  end

  test 'www redirect' do
    host! "www.#{Settings.tiddlyspot_host}"
    get '/'
    assert_redirected_to Settings.tiddlyspot_url_defaults
    assert_redirected_to 'http://tiddlyspot-test-example.com/'
  end

  def setup_site_with_content(name, content = 'some site html', is_private: false)
    host! "#{name}.#{Settings.tiddlyspot_host}"

    site = TspotSite.find_by_name(name)
    site.content_upload(content)
    site.update!(
      htpasswd: 'mulder:muG/6sge3L4Sc', # password 'trustno1'
      is_private:
    )
    site
  end

  test 'viewing a public site' do
    setup_site_with_content('coolsite', 'some site html', is_private: false)
    get '/'
    assert_success('some site html')
  end

  test 'viewing a public site with index.html' do
    setup_site_with_content('coolsite', 'some site html', is_private: false)
    get '/index.html'
    assert_success('some site html')
  end

  test 'viewing sites with weird names' do
    site = TspotSite.find_by_name('coolsite')

    [
      'cool.site',
      # Actually test fails with underscores - it gives this:
      # URI::InvalidURIError: the scheme http does not accept registry
      #   part: cool_site.tiddlyspot-example.com (or bad hostname?)
      #'cool_site',

    ].each do |name|
      site.update!(name:)
      setup_site_with_content(name, 'some site html', is_private: false)
      get '/'
      assert_success('some site html')
    end
  end

  test 'downloading a public site' do
    setup_site_with_content('coolsite', 'some site html', is_private: false)
    get '/download'
    assert_match 'filename="coolsite.html"', response.headers['Content-Disposition']
    assert_success('some site html')
  end

  test 'viewing a private site without auth' do
    setup_site_with_content('privatestuff', 'some site html', is_private: true)
    get '/'
    assert_unauthorized
  end

  test 'downloading a private site without auth' do
    setup_site_with_content('privatestuff', 'some site html', is_private: true)
    get '/download'
    assert_unauthorized
  end

  test 'viewing a private site with unsuccessful auth' do
    setup_site_with_content('privatestuff', 'some site html', is_private: true)
    get '/', headers: {
      'Authorization' => "Basic #{Base64.encode64('notes:noidea')}" }
    assert_unauthorized
  end

  test 'viewing a private site with successful auth' do
    setup_site_with_content('privatestuff', 'some site html', is_private: true)
    get '/', headers: {
      'Authorization' => "Basic #{Base64.encode64('mulder:trustno1')}" }
    assert_success('some site html')
  end

  test 'viewing site that was deleted' do
    host! "deletedsite.#{Settings.tiddlyspot_host}"
    get '/'
    assert_404
  end

  test 'redirect to url' do
    site = TspotSite.find_by_name('mysite')
    site.content_upload('hey now')
    site.update(redirect_to_url: 'http://some-url.example.com', is_private: false)

    host! "mysite.#{Settings.tiddlyspot_host}"
    get '/'
    # Actually it is not redirected yet, because of the feature flag
    assert_response :success

    # Enable the feature (in a clunky way)
    # Todo: Should have a good way to stub feature flags
    site.update(user_id: 1)
    site.user.update(user_type: UserType.superuser)

    host! "mysite.#{Settings.tiddlyspot_host}"
    get '/'
    assert_redirected_to 'http://some-url.example.com'
  end

  test 'redirect to thost site' do
    site = TspotSite.find_by_name('mysite')
    # Ensure it has a blob
    site.content_upload("dummy content")

    # Configure a redirect
    site.update(redirect_to_site_id: Site.find_by_name("mysite").id)

    # Confirm redirect happens
    host! "mysite.tiddlyspot-test-example.com"
    get '/'
    assert_redirected_to 'http://mysite.tiddlyhost-test-example.com'
  end

  test 'non-existing site produces 404' do
    host! "notexist.#{Settings.tiddlyspot_host}"
    get '/'
    assert_404
  end

  test 'empty html site produces 404' do
    site = TspotSite.find_by_name('mysite')
    site.content_upload('')
    host! "mysite.#{Settings.tiddlyspot_host}"
    get '/'
    assert_404
  end

  # Skip testing downloads with auth. I'm pretty sure they'll
  # behave correctly if all of the above is passing.
  def assert_unauthorized
    assert_response :unauthorized
    assert_select 'h1', '401 Unauthorized', response.body
  end

  def assert_success(expected_html)
    assert_response :success
    assert_match expected_html, response.body
  end

  def assert_404
    assert_response 404
    assert_select 'h1', '404 Not Found', response.body
  end
end
