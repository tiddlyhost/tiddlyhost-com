# frozen_string_literal: true

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
    assert_redirected_to 'http://tiddlyspot-example.com/'
  end

  def mocked_site(name)
    host! "#{name}.#{Settings.tiddlyspot_host}"

    mock = mock_helper do |m|
      m.expect(:name, name)
      m.expect(:htpasswd_file, 'mulder:muG/6sge3L4Sc')
      m.expect(:html_file, 'some site html')
    end

    yield mock if block_given?

    mock
  end

  def with_mocked_site(mock, &blk)
    TspotFetcher.stub(:new, mock, &blk)
  end

  test 'viewing a public site' do
    mock = mocked_site('coolsite') do |m|
      m.expect(:is_private?, false)
    end

    with_mocked_site(mock) { get '/' }
    assert_success('some site html', mock)
  end

  test 'viewing a public site with index.html' do
    mock = mocked_site('coolsite') do |m|
      m.expect(:is_private?, false)
    end

    with_mocked_site(mock) { get '/index.html' }
    assert_success('some site html', mock)
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
      mock = mocked_site(name) do |m|
        m.expect(:is_private?, false)
      end

      with_mocked_site(mock) { get '/' }
      assert_success('some site html', mock)
    end
  end

  test 'downloading a public site' do
    mock = mocked_site('coolsite') do |m|
      m.expect(:is_private?, false)
    end

    with_mocked_site(mock) { get '/download' }
    assert_match 'filename="coolsite.html"', response.headers['Content-Disposition']
    assert_success('some site html', mock)
  end

  test 'viewing a private site without auth' do
    mock = mocked_site('privatestuff') do |m|
      m.expect(:is_private?, true)
    end

    with_mocked_site(mock) { get '/' }
    assert_unauthorized(mock)
  end

  test 'downloading a private site without auth' do
    mock = mocked_site('privatestuff') do |m|
      m.expect(:is_private?, true)
    end

    with_mocked_site(mock) { get '/download' }
    assert_unauthorized(mock)
  end

  test 'viewing a private site with unsuccessful auth' do
    mock = mocked_site('privatestuff') do |m|
      m.expect(:is_private?, true)
    end

    with_mocked_site(mock) { get '/', headers: {
      'Authorization' => "Basic #{Base64.encode64('notes:noidea')}" } }
    assert_unauthorized(mock)
  end

  test 'viewing a private site with successful auth' do
    mock = mocked_site('privatestuff') do |m|
      m.expect(:is_private?, true)
    end

    with_mocked_site(mock) { get '/', headers: {
      'Authorization' => "Basic #{Base64.encode64('mulder:trustno1')}" } }
    assert_success('some site html', mock)
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
    site.update(redirect_to_site_id: 1)
    host! "mysite.#{Settings.tiddlyspot_host}"
    get '/'
    assert_redirected_to 'http://mysite.example.com'
  end

  test "viewing a site that doesn't exist" do
    host! "notexist.#{Settings.tiddlyspot_host}"
    get '/'
    assert_404
  end

  test 'viewing a stubbed site will cause it to be populated' do
    # Create a stub tspot site
    stubbed_site = TspotSite.create!(name: 'stubsite')
    assert stubbed_site.is_stub?

    mock = mocked_site('stubsite') do |m|
      m.expect(:is_private?, false)
    end

    with_mocked_site(mock) { get '/' }
    assert_success('some site html', mock)

    # Sanity check
    refute stubbed_site.reload.is_stub?
    assert stubbed_site.blob.present?
  end

  # Skip testing downloads with auth. I'm pretty sure they'll
  # behave correctly if all of the above is passing.

  def assert_unauthorized(mock)
    assert_response :unauthorized
    assert_select 'h1', '401 Unauthorized', response.body
    assert_mock mock
  end

  def assert_success(expected_html, mock)
    assert_response :success
    assert_match expected_html, response.body
    assert_mock mock
  end

  def assert_404(mock = nil)
    assert_response 404
    assert_select 'h1', '404 Not Found', response.body
    assert_mock mock if mock
  end
end
