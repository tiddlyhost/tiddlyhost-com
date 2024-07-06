# frozen_string_literal: true

require 'test_helper'

class SiteTest < ActiveSupport::TestCase
  setup do
    @site = Site.find_by_name('mysite')
    @user = @site.user
  end

  def user_query(sort_by = 'id')
    HubQuery.sites_for_user(@user, sort_by:)
  end

  def hub_query(opts = {})
    HubQuery.paginated_sites(**{
      page: 1,
      per_page: 10,
      sort_by: 'name',
      templates_only: nil,
      tag: nil,
      user: nil,
      search: nil
    }.merge(opts))
  end

  test 'everything' do
    # Make sure we have some content
    # (Being careful not to trigger the prune attachments job)
    @site.update(saved_content_files: [WithSavedContent.attachable_hash('some content')])
    assert_equal 1, @site.saved_content_files.count

    # Query includes one result with the expected content
    assert_equal 1, user_query.count
    assert_equal 'some content', user_query.first.file_download

    # Save another attachment and still there is only one result
    @site.saved_content_files.attach([WithSavedContent.attachable_hash('new content')])
    assert_equal 1, user_query.count
    assert_equal 'new content', user_query.first.file_download

    # ..even though the left join would create multiple rows
    assert_equal 2, @site.saved_content_files.count

    # ..no matter what the sort option is
    ['created_at asc', 'created_at desc'].each do |sort_opt|
      assert_equal 'new content', user_query(sort_opt).first.file_download
    end

    # Add a second site
    new_site = new_site_helper(name: 'bananas', user: @user)

    # Now there are two
    assert_equal 2, user_query.count

    # Sorting sanity
    new_site.update(raw_byte_size: 101)
    @site.update(raw_byte_size: 100)
    @site.update(is_private: true)

    {
      'created_at' => 'mysite',
      'created_at desc' => 'bananas',
      'name' => 'bananas',
      'raw_byte_size' => 'mysite',
      'is_private desc' => 'mysite',
      'is_private asc' => 'bananas',

    }.each do |sort_opt, expected_first_result|
      q = user_query(sort_opt)
      assert_equal expected_first_result, q.first.name, "Sort opt #{sort_opt}"
      assert_equal 2, q.count
    end

    # Now try the hub
    # (mysite is hub listed but we set it to private above)
    assert_equal 0, hub_query.count

    @site.update(is_private: false)
    assert_equal 1, hub_query.count

    # Add the other site to the hub
    new_site.update(is_searchable: true, is_private: false,
      # Dodge the "updated at least once" filter
      updated_at: Time.now + 10.seconds)

    # Now there are two
    assert_equal 2, hub_query.count

    # Try a few filters
    assert_equal 1, hub_query(search: 'nana').count
    assert_equal 0, hub_query(search: 'zanana').count
    assert_equal 2, hub_query(user: @user).count
    assert_equal 0, hub_query(user: users(:mary)).count
  end
end
