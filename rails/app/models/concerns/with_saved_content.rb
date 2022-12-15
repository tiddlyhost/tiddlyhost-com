
module WithSavedContent
  extend ActiveSupport::Concern

  included do
    # The new way to store site contents, replacing tiddlywiki_file.
    # Site saves now append a new attachment to this list.
    has_many_attached :saved_content_files

    # This field will no longer be written to, but will still be read
    # for sites that have nothing yet saved to saved_content_files.
    has_one_attached :tiddlywiki_file

    # Set allow_nil here though it's only needed for "stub" tspot sites.
    # (Todo: Remove allow_nil in future once those are gone.)
    # Note that current_content here is a method not an association.
    delegate :blob, to: :current_content, allow_nil: true

    delegate :byte_size, :key, :created_at, :content_type,
      to: :blob, prefix: true, allow_nil: true

    # Used in hub_query, which uses coalesce to pick out the relevant blob
    scope :with_blobs_for_query, ->{
      # New schema
      left_joins(saved_content_files_attachments: :blob).
        # Deprecated schema
        left_joins(tiddlywiki_file_attachment: :blob)
    }

    # For inspecting and reporting purposes
    scope :with_saved_content_files, ->{ joins(saved_content_files_attachments: :blob) } # With new schema
    scope :with_tiddlywiki_file, ->{ joins(tiddlywiki_file_attachment: :blob) } # With legacy schema
    scope :with_both_attachments, -> { with_saved_content_files.with_tiddlywiki_file } # Should be none

  end

  # Use the newest attachment from saved_content_files if it's present
  # otherwise fall back to the attachment in tiddlywiki_file
  def current_content
    @_current_content ||= saved_content_files.order('created_at DESC').limit(1).first || tiddlywiki_file
  end

  # Make sure the cached current_content is cleared on reload
  # (Primarily for testing, but probably a good idea regardless.)
  def reload
    @_current_content = nil
    super
  end

  COMPRESSED_CONTENT_TYPE = 'application/zlib'.freeze

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

  def self.attachment_params(new_content)
    tw_kind, tw_version = TwFile.light_get_kind_and_version(new_content)
    {
      # Record the uncompressed size before it gets compressed
      raw_byte_size: new_content.bytesize,

      # The kind and version of the site
      tw_kind: tw_kind,
      tw_version: tw_version,

      # It will append since our config has replace_on_assign_to_many set to false
      saved_content_files: [attachable_hash(new_content)],

      # The old way:
      #tiddlywiki_file: attachable_hash(new_content),
    }
  end

  # Used by Site records and TspotSite records that have been saved.
  def file_download
    blob_cache(:file_download) do
      WithSavedContent.decompress_html(current_content.download)
    end
  end

  # params_userfile should be an ActionDispatch::Http::UploadedFile
  def file_upload(params_userfile)
    content_upload(params_userfile.read)
  end

  # The tiddlywiki_file attribute is an attachment. Updating that
  # field is enough to make rails handle the new attachment upload
  def content_upload(new_content)
    update(WithSavedContent.attachment_params(new_content))

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
  def blob_cache(cache_type, tiddler_name=nil, &blk)
    blob_content_cache_key = [blob.cache_key, cache_type, tiddler_name].compact
    Rails.cache.fetch(blob_content_cache_key, expires_in: 4.weeks.from_now, &blk)
  end

  # Currently only used by TspotSite but define it here anyway.
  # Takes a block that runs on a cache miss.
  def site_cache(cache_type, &blk)
    site_content_cache_key = [cache_key, cache_type]
    Rails.cache.fetch(site_content_cache_key, expires_in: 4.weeks.from_now, &blk)
  end

  # For use with the TW site, not the site record itself
  def tw_etag
    blob.checksum
  end

  def keep_count
    1
  end

  def prune_attachments_later
    PruneAttachmentsJob.perform_later(self.class.name, self.id)
  end

  def prune_attachments_now
    # No pruning unless saved_content_files attachments are present
    return unless saved_content_files.attached?

    # Remove older attachments, keep the newest
    saved_content_files.order("created_at DESC").offset(keep_count).each(&:purge)

    # Clean up any legacy attachment
    tiddlywiki_file.purge if tiddlywiki_file.attached?
  end

end
