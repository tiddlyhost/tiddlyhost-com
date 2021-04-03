
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

    scope :for_hub, -> { searchable }

    scope :owned_by, ->(user) { where(user_id: user.id) }

    scope :search_for, ->(search_text) {
      where("#{table_name}.name ILIKE CONCAT('%',?,'%')", search_text).
      or(where("#{table_name}.description ILIKE CONCAT('%',?,'%')", search_text)) }
  end

  def download_url
    "#{url}/download"
  end

  def is_public?
    !is_private?
  end

end
