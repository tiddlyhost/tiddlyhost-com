
module SiteCommon
  extend ActiveSupport::Concern

  included do
    acts_as_taggable_on :tags

    include WithAccessCount

    # Optional is needed only for TspotSite records
    # Site records always have a user
    belongs_to :user, optional: true

    # Will be present for all sites except never-saved tspot sites
    has_one_attached :tiddlywiki_file

    # Set allow_nil here though it's only needed for TspotSite records
    # that have never been saved
    delegate :blob, to: :tiddlywiki_file, allow_nil: true

    delegate :byte_size, :key, :created_at, :content_type,
      to: :blob, prefix: true, allow_nil: true

    # Set allow_nil here though it's only needed for TspotSite that are unowned
    delegate :name, :email, :username, to: :user, prefix: true, allow_nil: true

    scope :private_sites, -> { where(is_private: true) }
    scope :public_sites, -> { where(is_private: false) }

    scope :public_non_searchable, -> { where(is_private: false, is_searchable: false) }

    # Private sites are not searchable even if is_searchable is set
    scope :searchable, -> { where(is_private: false, is_searchable: true) }

    scope :owned_by, ->(user) { where(user_id: user.id) }

    scope :search_for, ->(search_text) {
      where("#{table_name}.name ILIKE CONCAT('%',?,'%')", search_text).
      or(where("#{table_name}.description ILIKE CONCAT('%',?,'%')", search_text)) }

    scope :admin_search_for, ->(search_text) {
      search_for(search_text).
      or(where(id: search_text)) }

    scope :with_blob, -> { left_joins(tiddlywiki_file_attachment: :blob) }

    scope :compressed,   -> { with_blob.where(active_storage_blobs: { content_type: COMPRESSED_CONTENT_TYPE   }) }
    scope :uncompressed, -> { with_blob.where(active_storage_blobs: { content_type: UNCOMPRESSED_CONTENT_TYPE }) }

  end

  COMPRESSED_CONTENT_TYPE = 'application/zlib'.freeze
  UNCOMPRESSED_CONTENT_TYPE = 'text/html'.freeze

  def self.compress_html(raw_html)
    Zlib::Deflate.deflate(raw_html)
  end

  def self.decompress_html(compressed_html)
    Zlib::Inflate.inflate(compressed_html)
  end

  # Compress before attaching
  # See the find_or_build_blob method in
  #  lib/active_storage/attached/changes/create_one.rb
  #
  def self.attachable_hash(html_string)
    {
      io: StringIO.new(compress_html(html_string)),
      content_type: SiteCommon::COMPRESSED_CONTENT_TYPE,
      filename: 'index.html',
    }
  end

  # Used by Site records and TspotSite records that have been saved.
  def file_download
    blob_cache(:file_download) do
      raw_download = tiddlywiki_file.download
      is_compressed? ? SiteCommon.decompress_html(raw_download) : raw_download
    end
  end

  # params_userfile should be an ActionDispatch::Http::UploadedFile
  def file_upload(params_userfile)
    content_upload(params_userfile.read)
  end

  def content_upload(new_content)
    tiddlywiki_file.attach(SiteCommon.attachable_hash(new_content))
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

  def is_compressed?
    blob_content_type == COMPRESSED_CONTENT_TYPE
  end

  # Re-save a site in order to compress it, but preserve the blob created
  # timestamp. I used it to bulk-convert all sites to compressed format.
  # (Probably not useful any more since all sites are now compressed.)
  #
  def ensure_compressed
    return if is_compressed?

    original_timestamp = blob_created_at
    content_upload(file_download)
    blob.update_column(:created_at, original_timestamp)
  end

  # Currently only used by TspotSite but define it here anyway.
  # Takes a block that runs on a cache miss.
  def site_cache(cache_type, &blk)
    site_content_cache_key = [cache_key, cache_type]
    Rails.cache.fetch(site_content_cache_key, expires_in: 4.weeks.from_now, &blk)
  end

  def download_url
    "#{url}/download"
  end

  def is_public?
    !is_private?
  end

end
