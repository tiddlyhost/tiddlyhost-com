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
    @_current_content ||= saved_content_files.order('created_at DESC').limit(1).first
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
  def self.attachable_hash(html_string)
    {
      io: StringIO.new(compress_html(html_string)),
      content_type: COMPRESSED_CONTENT_TYPE,
      filename: 'index.html',
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
      saved_content_files: [*current_attachables, attachable_hash(new_content)],
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
    if user.feature_enabled?(:site_history)
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
end
