class Site < ApplicationRecord
  acts_as_taggable_on :tags

  belongs_to :user

  has_one_attached :tiddlywiki_file

  # The empty used when the site was created.
  # (It might not reflect what the site is now since the
  # user may have uploaded a different type of TiddlyWiki.)
  belongs_to :empty

  delegate :blob,
    to: :tiddlywiki_file, allow_nil: Settings.nil_blobs_ok?

  delegate :byte_size, :key, :created_at,
    to: :blob, prefix: true, allow_nil: Settings.nil_blobs_ok?

  delegate :name, :email, to: :user, prefix: true

  # Default for pagination
  self.per_page = 15

  scope :private_sites, -> { where(is_private: true) }
  scope :public_sites, -> { where(is_private: false) }

  scope :public_non_searchable, -> { where(is_private: false, is_searchable: false) }

  # Private sites are not searchable even if is_searchable is set
  scope :searchable, -> { where(is_private: false, is_searchable: true) }

  # The timestamps can be a few milliseconds apart, so that's why we need the interval
  # Todo: blob_created_at would be a more useful timestamp to use here than updated_at.
  scope :never_updated,         -> { where("AGE(sites.updated_at, sites.created_at) <= INTERVAL '0.5 SECOND'") }
  scope :updated_at_least_once, -> { where("AGE(sites.updated_at, sites.created_at) >  INTERVAL '0.5 SECOND'") }

  scope :owned_by, ->(user) { where(user_id: user.id) }

  scope :search_for, ->(search_text) {
    where("name LIKE CONCAT('%',?,'%')", search_text).or(
      where("description ILIKE CONCAT('%',?,'%')", search_text))
        # TODO: search tags also
  }

  def self.tags_for_searchable_sites
    tags = ActsAsTaggableOn::Tagging.where(
      taggable_id: Site.searchable.pluck(:id), taggable_type: 'Site')

    ActsAsTaggableOn::Tag.where(id: tags.pluck(:tag_id)).order('taggings_count desc');
  end

  validates :name,
    presence: true,
    uniqueness: true,
    length: {
      # Let's reserve sites with one or two letter names
      minimum: 3,
      # RFC1035 says 63 is the maximum size of a subdomain...
      maximum: 63,
    },
    format: {
      # Must be only lowercase letters, numerals, and dashes
      # Must not have more than one consecutive dash
      # Must not start or end with a dash
      # (See also app/javascript/packs/application.js)
      without: / [^a-z0-9-] | -- | ^- | -$ /x,
      message: "'%{value}' is not allowed. Please choose a different site name.",
    },
    exclusion: {
      # Let's reserve a few common subdomains
      in: %w[
        www
        ftp
        pop
        imap
        smtp
        mail
        help
        faq
        support
        wiki
      ],
      message: "'%{value}' is reserved. Please choose a different site name.",
    }

  def increment_view_count
    # Using update_column to avoid automatically touching updated_at
    update_column(:view_count, view_count + 1)
  end

  def increment_access_count
    # Using update_column to avoid automatically touching updated_at
    update_column(:access_count, access_count + 1)
  end

  def touch_accessed_at
    # Using update_column to avoid automatically touching updated_at
    update_column(:accessed_at, Time.now)
  end

  def th_file
    @_th_file ||= ThFile.new(tiddlywiki_file.download)
  end

  def looks_valid?
    th_file.looks_valid?
  end

  def html_content
    th_file.apply_tiddlyhost_mods(name).to_html
  end

  def url
    Settings.subdomain_site_url(name)
  end

  def download_url
    "#{url}/download"
  end

  def favicon_asset_name
    'favicon-green.ico'
  end

  def is_public?
    !is_private?
  end

end
