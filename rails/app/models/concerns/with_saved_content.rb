module WithSavedContent
  extend ActiveSupport::Concern

  included do
    # Site saves append a new attachment to this list.
    has_many_attached :saved_content_files

    # Set allow_nil here though it's only needed for "stub" tspot sites.
    # (Todo: Remove allow_nil in future once those are gone.)
    # Note that current_content here is a method not an association.
    delegate :blob, to: :current_content, allow_nil: true

    delegate :byte_size, :key, :created_at, :content_type,
      to: :blob, prefix: true, allow_nil: true

    # Used in hub_query
    scope :with_blobs_for_query, -> { left_joins(saved_content_files_attachments: :blob) }
  end

  # Use the newest attachment from saved_content_files
  def current_content
    @_current_content ||= saved_content_files_newest_first.limit(1).first
  end

  def saved_content_files_newest_first
    saved_content_files.order(created_at: :desc)
  end

  def saved_version_count
    saved_content_files.count
  end

  # For use when extracting a specific version of a site its save history
  def specific_saved_content_file(blob_id)
    saved_content_files.where(blob_id:).first
  end

  # Make sure the cached current_content is cleared on reload
  # (Primarily for testing, but probably a good idea regardless.)
  def reload
    @_current_content = nil
    super
  end

  COMPRESSED_CONTENT_TYPE = 'application/zlib'

  def self.compress_html(raw_html)
    Zlib::Deflate.deflate(raw_html)
  end

  def self.decompress_html(compressed_html)
    Zlib::Inflate.inflate(compressed_html)
  end

  # See the `find_or_build_blob` method in
  #  lib/active_storage/attached/changes/create_one.rb
  # in the active_storage gem to see how this hash gets
  # used and why we need these particular keys.
  #
  def self.attachable_hash(html_string, storage_service = nil)
    {
      io: StringIO.new(compress_html(html_string)),
      content_type: COMPRESSED_CONTENT_TYPE,
      filename: 'index.html',
      # If this is nil the default from config.active_storage.service will be used
      service_name: storage_service,
    }
  end

  # Todo: Refactor and make this less clunky. Perhaps make use of
  # `saved_content_files.attach` which would be more typical.
  #
  def self.attachment_params(new_content, record = nil)
    tw_kind, tw_version = TwFile.light_get_kind_and_version(new_content)
    current_attachables = record.present? ? record.saved_content_files.blobs : []
    {
      # Record the uncompressed size before it gets compressed
      raw_byte_size: new_content.bytesize,

      # The kind and version of the site
      tw_kind:,
      tw_version:,

      # We want to append the new attachment to the existing attachments. By default
      # rails won't do that, so that's why we include the existing blobs here.
      # (Reproduces the `replace_on_assign_to_many` config behavior from Rails 6)
      #
      saved_content_files: [*current_attachables, attachable_hash(new_content, record&.storage_service)],
    }
  end

  # Used by Site records and TspotSite records that have been saved.
  def file_download(blob_id = nil)
    # Don't bother to cache older versions of the site
    return uncached_file_download(blob_id) if blob_id

    # Do cache the latest version of the site
    blob_cache(:file_download) do
      uncached_file_download
    end
  end

  def uncached_file_download(blob_id = nil)
    if blob_id
      # The exact version as specified by the blob id
      downloaded_content = specific_saved_content_file(blob_id)&.download
    else
      # The latest version
      downloaded_content = current_content.download
    end

    WithSavedContent.decompress_html(downloaded_content) unless downloaded_content.nil?
  end

  # params_userfile should be an ActionDispatch::Http::UploadedFile
  def file_upload(params_userfile)
    content_upload(params_userfile.read)
  end

  def content_upload(new_content)
    ok = update(WithSavedContent.attachment_params(new_content, self))
    return unless ok

    # See below
    prune_attachments_later

    # See app/models/concerns/with_thumbnail
    update_thumbnail_later
  end

  # When a site is saved it gets a brand new blob. So if we use the blob's
  # cache key then any cache related to the site's content will become stale
  # when the site is saved, i.e. exactly when it needs to.
  # Takes a block that runs on a cache miss.
  #
  def blob_cache(cache_type, tiddler_name = nil, &)
    blob_content_cache_key = [blob.cache_key, cache_type, tiddler_name].compact
    Rails.cache.fetch(blob_content_cache_key, expires_in: 4.weeks, &)
  end

  # Currently only used by TspotSite but define it here anyway.
  # Takes a block that runs on a cache miss.
  def site_cache(cache_type, &)
    site_content_cache_key = [cache_key, cache_type]
    Rails.cache.fetch(site_content_cache_key, expires_in: 4.weeks, &)
  end

  # For use with the TW site, not the site record itself
  def tw_etag
    blob.checksum
  end

  def prune_attachments_later
    PruneAttachmentsJob.perform_later(self.class.name, self.id)
  end

  def prune_attachments_now
    if user&.feature_enabled?(:site_history)
      # When the site history feature is enabled we pay attention to whether
      # the saved versions have labels. Revisions with a label will be kept
      # in preference to revisions without a label
      ordered_files = saved_content_files.
        left_outer_joins(:attachment_label).
        order(Arel.sql('attachment_labels.text IS NULL ASC')).
        order('created_at DESC')
    else
      # Otherwise it's just based on the timestamp
      ordered_files = saved_content_files.
        order('created_at DESC')
    end

    # Keep so many and purge the rest
    ordered_files.offset(keep_count).each(&:purge)
  end

  #---------------------------------------------------------------------------
  # See also scripts/recover_missing_blobs.rb
  # (This doesn't really belong here, but never mind.)
  #
  # Sometimes a blob we're tracking doesn't actually exist in the storage
  # service. Not sure how it happens. Was there an S3 outage? Did we have
  # some server instability and the write failed? Did the blob record somehow
  # switch storage back ends without moving the data? Was it deleted from
  # the storage service? Did the key change somehow? Idk.
  def self.blob_exists_in_storage?(some_blob)
    some_blob.service.exist?(some_blob.key)
  end

  # If the current blob is missing from the storage service then the site is
  # very broken. Trying to viewing it throws ActiveStorage::FileNotFoundError
  # and users see a 500 internal server error.
  def main_blob_missing?
    blob.present? && !WithSavedContent.blob_exists_in_storage?(blob)
  end

  # Find the newest blob that is not missing in the storage service. This
  # should be the best version to use for recovering the site. Changes from
  # the lost blob will still be lost, but there's not much we can do about it.
  def newest_good_blob
    saved_content_files_newest_first.
      includes(:blob).
      map(&:blob).
      compact.select { WithSavedContent.blob_exists_in_storage?(it) }.
      first
  end

  # Restore the broken site by uploading the most recent saved version of the
  # site where the blob key really does exist in the storage service.
  def restore_missing_main_blob!
    raise "Main blob not missing!" unless main_blob_missing?
    raise "No good blob found!" unless newest_good_blob.present?

    # Similar to restore_version in the SiteHistory controller concern
    content_upload(file_download(newest_good_blob.id))
  end
  #---------------------------------------------------------------------------
end
