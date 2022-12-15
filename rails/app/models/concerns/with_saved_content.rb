
module WithSavedContent
  extend ActiveSupport::Concern

  included do
    # Will be present for all sites except never-saved tspot sites
    has_one_attached :tiddlywiki_file

    # Set allow_nil here though it's only needed for TspotSite records
    # that have never been saved
    delegate :blob, to: :tiddlywiki_file, allow_nil: true

    delegate :byte_size, :key, :created_at, :content_type,
      to: :blob, prefix: true, allow_nil: true

    scope :with_blob, -> { left_joins(tiddlywiki_file_attachment: :blob) }

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

      # This is the actual attachment
      tiddlywiki_file: attachable_hash(new_content),
    }
  end

  # Used by Site records and TspotSite records that have been saved.
  def file_download
    blob_cache(:file_download) do
      WithSavedContent.decompress_html(tiddlywiki_file.download)
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

end
