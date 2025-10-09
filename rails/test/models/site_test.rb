require 'test_helper'

class SiteTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  setup do
    @site = Site.find_by_name('mysite')
  end

  test 'url' do
    assert_equal 'mysite.tiddlyhost-test-example.com', @site.host
    assert_equal 'http://mysite.tiddlyhost-test-example.com', @site.url
    assert_equal 'http://tiddlyhost-test-example.com', Settings.main_site_url
  end

  test 'name validation' do
    # These names are invalid
    [
      '-aaa',
      'aaa-',
      '-aaa-',
      'a--a',
      'Aaa',
      'aa',
      'abc$',
      'x' * 64,
      'ftp',
      'www',
      'wiki',
      "foo\nbar",
      "foo\tbar",
      'foo bar',
    ].each do |invalid_name|
      @site.update(name: invalid_name)
      refute @site.valid?, "#{invalid_name} unexpectedly allowed!"
    end

    # These names are valid
    [
      'aaa',
      'aa-aa',
      'bbb-cc-dd',
      'x' * 63,
      'ab9',
      '777',
      '123-aaa',
      'myftp',
      'shit', # Hmm...
    ].each do |valid_name|
      @site.update(name: valid_name)
      assert @site.valid?, "#{valid_name} unexpectedly disallowed!"
    end
  end

  test 'view counts and timestamps' do
    orig_updated_at = @site.updated_at.to_i
    orig_accessed_at = @site.accessed_at.to_i
    orig_view_count = @site.view_count
    orig_access_count = @site.access_count

    @site.touch_accessed_at
    # The accessed_at field is touched
    assert_operator orig_accessed_at, :<, @site.accessed_at.to_i
    # The updated_at field is not
    assert_equal orig_updated_at, @site.updated_at.to_i

    @site.increment_view_count
    @site.increment_access_count
    # The counters were incremented
    assert_equal orig_view_count + 1, @site.reload.view_count
    assert_equal orig_access_count + 1, @site.reload.access_count
    # The updated_at field is untouched
    assert_equal orig_updated_at, @site.updated_at.to_i
  end

  test 'when to use put saver' do
    {
      true => [
        { tw_kind: 'feather' },
        { tw_kind: 'tw5', tw_version: '5.2.3' },
        { tw_kind: 'tw5', tw_version: '5.2.2', prefer_put_saver: true },

        # Unlikely edge case showing preference is ignored
        { tw_kind: 'feather', prefer_upload_saver: true },
      ],

      false => [
        { tw_kind: 'classic' },
        { tw_kind: 'tw5', tw_version: '5.2.2' },
        { tw_kind: 'tw5', tw_version: '5.2.3', prefer_upload_saver: true },

        # Edge case to demonstrate that prefer upload takes precendent if both are set
        { tw_kind: 'tw5', tw_version: '5.2.2', prefer_put_saver: true, prefer_upload_saver: true },
        { tw_kind: 'tw5', tw_version: '5.2.3', prefer_put_saver: true, prefer_upload_saver: true },

        # Unlikely edge case showing preference is ignored
        { tw_kind: 'classic', prefer_put_saver: true },
      ],

    }.each do |expected, list|
      list.each do |attrs|
        @site.update!({ prefer_upload_saver: false, prefer_put_saver: false }.merge(attrs))
        assert_equal expected, @site.use_put_saver?, attrs.inspect
      end
    end
  end

  test 'attachment behavior' do
    # To begin with, site has no content (which is not a
    # realistic scenario, but it's what we have in fixtures.)
    refute @site.saved_content_files.attached?

    # Upload some content
    @site.content_upload('foo123')

    # The new schema has an attachment now
    assert @site.saved_content_files.attached?

    # Sanity check the content
    assert_equal 'foo123', @site.file_download
  end

  def setup_some_saved_versions
    @site.content_upload('boop5')
    @site.content_upload('boop6')
    @boop6_blob_id = @site.reload.blob.id

    @site.content_upload('boop7')
    @boop7_blob_id = @site.reload.blob.id

    @site.content_upload('boop8')
    @boop8_blob_id = @site.reload.blob.id

    @site.content_upload('boop9')

    assert_equal 5, @site.reload.saved_content_files.count
  end

  test 'prune attachments respects keep count' do
    setup_some_saved_versions

    @site.stub(:keep_count, 100) do
      @site.prune_attachments_now
      # All versions are kept
      assert_equal 5, @site.reload.saved_content_files.count
    end

    @site.stub(:keep_count, 3) do
      @site.prune_attachments_now
      # Three versions kept
      assert_equal 3, @site.reload.saved_content_files.count
    end

    # We can still access the current versions
    assert_equal 'boop9', @site.file_download
    assert_equal 'boop9', @site.file_download(@site.blob.id)

    # We can access older versions by their blob id
    assert_equal 'boop8', @site.file_download(@boop8_blob_id)
    assert_equal 'boop7', @site.file_download(@boop7_blob_id)

    # This one is gone now since we kept only three
    assert_nil @site.file_download(@boop6_blob_id)

    # Create another site
    new_site = new_site_helper(name: 'newsite', user: @site.user)
    new_site_blob_id = new_site.blob.id
    assert_match(/UnaMesa Association/, new_site.file_download(new_site_blob_id))

    # Can't access blobs from other sites
    assert_nil @site.file_download(new_site_blob_id)
  end

  test 'prune attachments considers labels' do
    setup_some_saved_versions

    @site.stub(:keep_count, 3) do
      Settings::Features.stub(:site_history_enabled?, true) do
        # In the previous test we expected boop6 to be pruned
        # Here we'll give it a label and then confirm it is kept
        attachment = @site.specific_saved_content_file(@boop6_blob_id)
        attachment.attachment_label = 'some label'
        @site.prune_attachments_now

        # As expected, boop6 was kept
        assert_equal 'boop6', @site.file_download(@boop6_blob_id)

        # Actually the newer boop7 was pruned instead
        assert_nil @site.file_download(@boop7_blob_id)
      end
    end
  end

  test 'prune job scheduled' do
    assert_enqueued_with(job: PruneAttachmentsJob) do
      @site.content_upload('foo123')
    end

    job_wrapper = ActiveJob::QueueAdapters::DelayedJobAdapter::JobWrapper.new(enqueued_jobs.first)
    # (It should use the default from Delayed::Worker.DEFAULT_MAX_ATTEMPTS, which is 25)
    assert_nil job_wrapper.max_attempts
  end

  test 'thumbnail job scheduled' do
    assert_enqueued_with(job: GenerateThumbnailJob) do
      @site.content_upload('foo123')
    end

    # See rails/config/initializers/active_job_delayed_job_param_fix.rb
    job_wrapper = ActiveJob::QueueAdapters::DelayedJobAdapter::JobWrapper.new(enqueued_jobs.last)
    assert_equal 1, job_wrapper.max_attempts
  end

  test 'thumbnail generation' do
    @site.content_upload('foo123')
    refute @site.thumbnail.present?
    GenerateThumbnailJob.perform_now('Site', @site.id)
    assert @site.reload.thumbnail.present?
    assert_equal 'image/png', @site.thumbnail.blob.content_type
  end

  test 'thumbnail storage service' do
    [
      [true, 'test1'],
      [false, 'test2'],

    ].each do |is_private, expected|
      @site.update(is_private:)
      @site.send(:thumbnail_attach, 'bogus')
      assert @site.thumbnail.present?
      assert_equal expected, @site.thumbnail.blob.service_name
    end
  end

  test 'switching storage service' do
    # Create three files with alternating storage services
    @site.update(storage_service: 'test1')
    @site.content_upload('foo123')

    @site.update(storage_service: 'test2')
    @site.content_upload('bar123')

    @site.update(storage_service: 'test')
    @site.content_upload('baz123')

    # Sanity check
    assert_equal 3, @site.saved_content_files.count
    assert_equal(%w[test1 test2 test], @site.saved_content_files.map { |f| f.blob.service_name })
    assert_equal 'test', @site.current_content.blob.service_name
    assert_equal 'baz123', @site.uncached_file_download

    # Delete the current file and sanity check
    @site.current_content.purge
    assert_equal 'test2', @site.reload.current_content.blob.service_name
    assert_equal 'bar123', @site.uncached_file_download

    # Delete the current file and sanity check
    @site.current_content.purge
    assert_equal 'test1', @site.reload.current_content.blob.service_name
    assert_equal 'foo123', @site.uncached_file_download
  end

  test 'blob missing in storage' do
    # It's a little confusing, but `main_blob_missing?` is true if there is a
    # blob record but the storage service lost the file for it. So if we have
    # no blob records at all then it's false. This is an edge case, since sites
    # with zero saved versions in general don't exist.
    assert_equal 0, @site.saved_version_count
    assert_not @site.main_blob_missing?

    # Upload some content so we do have a blob
    @site.content_upload('test content')
    assert_equal 1, @site.saved_version_count
    blob = @site.reload.blob

    # The blob is present in the storage service
    assert WithSavedContent.blob_exists_in_storage?(blob)
    assert_not @site.main_blob_missing?

    # The blob is missing in the storage service
    blob.service.stub(:exist?, ->(_key) { false }) do
      assert_not WithSavedContent.blob_exists_in_storage?(blob)
      assert @site.main_blob_missing?
    end
  end

  test 'restore missing main blob' do
    # Create two saved versions
    @site.content_upload('older version')
    old_blob = @site.reload.blob
    @site.content_upload('current version')

    # Sanity check
    assert_equal 2, @site.reload.saved_version_count
    assert_equal 'current version', @site.file_download

    # Main blob is not missing, no restore is done
    assert_raises(RuntimeError, "Main blob not missing!") do
      @site.reload.restore_missing_main_blob!
    end

    # Main blob is missing, but no non-missing other blob was found
    WithSavedContent.stub(:blob_exists_in_storage?, ->(_blob) { false }) do
      assert_raises(RuntimeError, "No good blob found!") do
        @site.reload.restore_missing_main_blob!
      end
    end

    # Main blob missing, and there is an non-missing older blob available
    WithSavedContent.stub(:blob_exists_in_storage?, ->(blob) { blob.id == old_blob.id }) do
      @site.reload.restore_missing_main_blob!

      # Should have created a new version with the older content
      assert_equal 3, @site.reload.saved_content_files.count
      assert_equal 'older version', @site.file_download
    end
  end
end
