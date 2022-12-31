require "test_helper"

class SiteTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  setup do
    @site = Site.find_by_name('mysite')
  end

  test "url" do
    assert_equal 'mysite.example.com', @site.host
    assert_equal 'http://mysite.example.com', @site.url
    assert_equal 'http://example.com', Settings.main_site_url
  end

  test "name validation" do

    # These names are invalid
    [
      "-aaa",
      "aaa-",
      "-aaa-",
      "a--a",
      "Aaa",
      "aa",
      "abc$",
      "x" * 64,
      "ftp",
      "www",
      "wiki",
      "foo\nbar",
      "foo\tbar",
      "foo bar",
    ].each do |invalid_name|
      @site.update(name: invalid_name)
      refute @site.valid?, "#{invalid_name} unexpectedly allowed!"
    end

    # These names are valid
    [
      "aaa",
      "aa-aa",
      "bbb-cc-dd",
      "x" * 63,
      "ab9",
      "777",
      "123-aaa",
      "myftp",
      "shit", # Hmm...
    ].each do |valid_name|
      @site.update(name: valid_name)
      assert @site.valid?, "#{valid_name} unexpectedly disallowed!"
    end

  end

  test "view counts and timestamps" do
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

  test "when to use put saver" do
    {
      true => [
        {tw_kind: "feather"},
        {tw_kind: "tw5", tw_version: "5.2.3"},
        {tw_kind: "tw5", tw_version: "5.2.2", prefer_put_saver: true},

        # Unlikely edge case showing preference is ignored
        {tw_kind: "feather", prefer_upload_saver: true},
      ],

      false => [
        {tw_kind: "classic"},
        {tw_kind: "tw5", tw_version: "5.2.2"},
        {tw_kind: "tw5", tw_version: "5.2.3", prefer_upload_saver: true},

        # Edge case to demonstrate that prefer upload takes precendent if both are set
        {tw_kind: "tw5", tw_version: "5.2.2", prefer_put_saver: true, prefer_upload_saver: true},
        {tw_kind: "tw5", tw_version: "5.2.3", prefer_put_saver: true, prefer_upload_saver: true},

        # Unlikely edge case showing preference is ignored
        {tw_kind: "classic", prefer_put_saver: true},
      ],

    }.each do |expected, list|
      list.each do |attrs|
        @site.update!({prefer_upload_saver: false, prefer_put_saver: false}.merge(attrs))
        assert_equal expected, @site.use_put_saver?, attrs.inspect
      end
    end
  end

  def upload_content(site, content)
    site.saved_content_files.attach([WithSavedContent.attachable_hash(content)])
  end

  def upload_legacy_content(site, content)
    site.tiddlywiki_file.attach(WithSavedContent.attachable_hash(content))
  end

  test "attachment behavior" do
    # To begin with, site has no content (which is not a
    # realistic scenario, but it's what we have in fixtures.)
    refute @site.tiddlywiki_file.attached?
    refute @site.saved_content_files.attached?

    # Upload some content
    upload_content(@site, "foo123")

    # The old schema is not touched
    refute @site.tiddlywiki_file.attached?

    # The new schema has an attachment now
    assert @site.saved_content_files.attached?

    # Sanity check the content
    assert_equal "foo123", @site.file_download
  end

  test "attachment behavior with tiddlywiki_file" do
    # Simulate a "legacy" site with an attachment in tiddlywiki_file
    upload_legacy_content(@site, "bar234")
    assert @site.tiddlywiki_file.attached?
    refute @site.saved_content_files.attached?

    # The legacy content is used as expected
    assert_equal "bar234", @site.file_download

    # Upload to saved_content_files the legacy content is ignored
    upload_content(@site, "baz345")
    assert @site.saved_content_files.attached?
    assert_equal "baz345", @site.reload.file_download

    # ...even though the legacy content is still there
    assert @site.tiddlywiki_file.attached?

    # Uploading again should append to saved_content_files
    upload_content(@site, "boop7")
    assert_equal "boop7", @site.reload.file_download
    assert_equal 2, @site.saved_content_files.count

    upload_content(@site, "boop8")
    upload_content(@site, "boop9")
    assert_equal "boop9", @site.reload.file_download
    assert_equal 4, @site.saved_content_files.count

    # Pruning the old versions does what we expect
    @site.prune_attachments_now
    assert_equal 1, @site.saved_content_files.count

    # It cleans up the legacy attachment as well
    refute @site.tiddlywiki_file.attached?

    # The latest content is the one kept
    assert_equal "boop9", @site.reload.file_download
  end

  test "prune attachments respects keep count" do
    upload_content(@site, "boop5")
    upload_content(@site, "boop6")
    boop6_blob_id = @site.reload.blob.id

    upload_content(@site, "boop7")
    boop7_blob_id = @site.reload.blob.id

    upload_content(@site, "boop8")
    boop8_blob_id = @site.reload.blob.id

    upload_content(@site, "boop9")
    assert_equal 5, @site.reload.saved_content_files.count

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
    assert_equal "boop9", @site.file_download
    assert_equal "boop9", @site.file_download(@site.blob.id)

    # We can access older versions by their blob id
    assert_equal "boop8", @site.file_download(boop8_blob_id)
    assert_equal "boop7", @site.file_download(boop7_blob_id)

    # This one is gone now since we kept only three
    assert_nil @site.file_download(boop6_blob_id)

    # Create another site
    new_site = new_site_helper(name: "newsite", user: @site.user)
    new_site_blob_id = new_site.blob.id
    assert_match /UnaMesa Association/, new_site.file_download(new_site_blob_id)

    # Can't access blobs from other sites
    assert_nil @site.file_download(new_site_blob_id)
  end

  test "prune job scheduled" do
    assert_enqueued_with(job: PruneAttachmentsJob) do
      @site.content_upload("foo123")
    end
  end

  test "thumbnail job scheduled" do
    assert_enqueued_with(job: GenerateThumbnailJob) do
      @site.content_upload("foo123")
    end
  end

  test "thumbnail generation" do
    @site.content_upload("foo123")
    refute @site.thumbnail.present?
    GenerateThumbnailJob.perform_now('Site', @site.id)
    assert @site.reload.thumbnail.present?
    assert_equal 'image/png', @site.thumbnail.blob.content_type
  end

end
