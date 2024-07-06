# frozen_string_literal: true

module SiteCommon
  extend ActiveSupport::Concern

  included do
    acts_as_taggable_on :tags

    include WithSavedContent
    include WithThumbnail
    include WithAccessCount
    include AdminSearchable
    include SafeModeUrls

    # Optional is needed only for TspotSite records
    # Site records always have a user
    belongs_to :user, optional: true

    # Set allow_nil here though it's only needed for TspotSite that are unowned
    delegate :name, :email, :username, to: :user, prefix: true, allow_nil: true

    scope :private_sites, -> { where(is_private: true) }
    scope :public_sites, -> { where(is_private: false) }

    scope :public_non_searchable, -> { where(is_private: false, is_searchable: false) }

    # Private sites are not searchable even if is_searchable is set
    scope :searchable, -> { where(is_private: false, is_searchable: true) }

    scope :owned_by, ->(user) { where(user_id: user.id) }

    scope :search_for, lambda { |search_text|
      where("#{table_name}.name ILIKE CONCAT('%',?,'%')", search_text)
      .or(where("#{table_name}.description ILIKE CONCAT('%',?,'%')", search_text))
      .or(search_tags(search_text))
    }

    scope :search_tags, lambda { |search_text|
      search_words = search_text.split(/\s+/)
      ids = tagged_with(search_words, any: true).pluck(:id)
      where("#{table_name}.id" => ids)
    }

    validates :tw_kind, inclusion: { in: SiteCommon::KIND_VALS }, allow_nil: true
  end

  KINDS = {
    'tw5'     => 'TiddlyWiki (self-contained)',
    'tw5x'    => 'TiddlyWiki (external core)',
    'classic' => 'TiddlyWiki Classic',
    'feather' => 'Feather Wiki',
  }.freeze

  KIND_LOGOS = {
    # Todo maybe: A different image for 'tw'
    'tw'      => 'tw5-icon.ico',
    'tw5'     => 'tw5-icon.ico',
    'tw5x'    => 'tw5x-icon.ico',
    'classic' => 'classic-icon.ico',
    'feather' => 'feather-icon.svg',
  }.freeze

  # (These are not currently used)
  KIND_URLS = {
    'tw5'     => 'https://tiddlywiki.com/',
    # Todo: Think of a better url for tw5x
    'tw5x'    => CGI.escape('https://tiddlywiki.com/#:[[Using the external JavaScript template]] HelloThere'),
    'classic' => 'https://classic.tiddlywiki.com/',
    'feather' => 'https://feather.wiki/',
  }.freeze

  KIND_VALS = KINDS.keys.freeze

  # See also TwFile.is_#{kind}? methods which look at the content, unlike these
  #
  SiteCommon::KIND_VALS.each do |kind|
    define_method("is_#{kind}?") do
      tw_kind == kind
    end
  end

  def kind_title
    SiteCommon::KINDS[tw_kind] if tw_kind
  end

  def kind_logo_image
    SiteCommon::KIND_LOGOS[tw_kind] if tw_kind
  end

  # Remove Feather Wiki variant prefix, e.g. "Warbler_1.5.0" -> "1.5.0"
  def tw_version_short
    return tw_version unless is_feather?

    tw_version&.sub(/^[A-Za-z]+_/, '')
  end

  def download_url
    "#{url}/download"
  end

  def is_public?
    !is_private?
  end

  def hub_listed?
    is_public? && is_searchable?
  end

  def long_name
    URI(url).hostname
  end

  # Three methods used in app/views/sites/_access_chooser
  #
  def access_public?
    is_public? && !hub_listed?
  end

  def access_private?
    is_private?
  end

  def access_hub_listed?
    hub_listed?
  end
end
