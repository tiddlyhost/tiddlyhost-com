
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
    delegate :byte_size, :key, :created_at, to: :blob, prefix: true, allow_nil: true

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

    scope :with_blob, -> { left_joins(tiddlywiki_file_attachment: :blob) }
  end

  # Used by Site records and TspotSite records that have been saved.
  def file_download
    blob_cache(:file_download) do
      tiddlywiki_file.download
    end
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

  def download_url
    "#{url}/download"
  end

  def is_public?
    !is_private?
  end

end
