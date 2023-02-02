class Site < ApplicationRecord
  include SiteCommon

  # The empty used when the site was created.
  # (It might not reflect what the site is now since the
  # user may have uploaded a different type of TiddlyWiki.)
  belongs_to :empty

  # Will be set if the site was created as a clone of another site
  # (Beware the original site might have been deleted, so the association
  # could return nil even if the id field is present.)
  belongs_to :cloned_from, optional: true, class_name: :Site

  # The timestamps can be a few milliseconds apart, so that's why we need the interval
  # Todo: blob_created_at would be a more useful timestamp to use here than updated_at.
  scope :never_updated,         -> { where("AGE(sites.updated_at, sites.created_at) <= INTERVAL '0.5 SECOND'") }
  scope :updated_at_least_once, -> { where("AGE(sites.updated_at, sites.created_at) >  INTERVAL '0.5 SECOND'") }

  scope :for_hub, -> { searchable.updated_at_least_once }

  scope :templates_only, -> { where(is_private: false, allow_public_clone: true) }

  # For compatibility with tspot sites
  scope :not_deleted, -> { all }

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

  def th_file
    @_th_file ||= ThFile.new(file_download)
  end

  def th_file_for_blob_id(blob_id)
    ThFile.new(file_download(blob_id))
  end

  def looks_valid?
    th_file.looks_valid?
  end

  def html_content(is_logged_in: false)
    th_file.apply_tiddlyhost_mods(name,
      is_logged_in: is_logged_in, use_put_saver: use_put_saver?).to_html
  end

  def html_content_for_blob_id(blob_id, is_logged_in: false)
    th_file_for_blob_id(blob_id).apply_tiddlyhost_mods(name,
      # Note: There might be some tricky edge cases around the value of use_put_saver?
      # here since it's based on the current site, not the specific version being fetched
      is_logged_in: is_logged_in, use_put_saver: use_put_saver?).to_html
  end

  def json_data(opts={})
    th_file.tiddlers_data(**opts)
  end

  def tiddler_data(tiddler_name)
    blob_cache(:tiddler_data, tiddler_name) do
      th_file.tiddler_data(tiddler_name)
    end
  end

  def download_content(local_core: false)
    th_file.apply_tiddlyhost_mods(name, for_download: true, local_core: local_core).to_html
  end

  def download_content_for_blob_id(blob_id)
    # Todo maybe: Consider the local core option here
    ThFile.new(file_download(blob_id)).apply_tiddlyhost_mods(name, for_download: true).to_html
  end

  # Could be more clever here and try to read it from the script src,
  # but let's keep it simple to begin with.
  def core_js_name
    "tiddlywikicore-#{tw_version}.js"
  end

  def core_js_content
    File.read("#{Rails.root}/public/#{core_js_name}")
  end

  def use_put_saver?
    # Feather wiki always uses put saver
    return true if is_feather?

    # Classic always uses upload saver
    return false if is_classic?

    # Use any user specified preferences from the site's advanced options
    return false if prefer_upload_saver?
    return true if prefer_put_saver?

    # Otherwise use whatever the default is based on the version
    default_to_put_saver?
  end

  def cloneable_by_user?(some_user)
    # You can always clone your own site
    return true if some_user && some_user == self.user

    # You can clone a publicly cloneable site
    is_public? && allow_public_clone?
  end

  def cloneable_by_public?
    cloneable_by_user?(nil)
  end

  # Any TiddlyWiki5 should work with the put saver, but there are some error
  # message improvements in 5.2.3 that provide a marginally better UX when the
  # save fails, so let's use the put saver by default from that version onwards
  # and stick with the legacy upload saver for earler versions
  DEFAULT_TO_PUT_SAVER_FROM_VERSION = "5.2.3".freeze

  def default_to_put_saver?
    # Use Gem::Version here to handle the comparison properly, e.g. so "5.10" > "5.9"
    Gem::Version.new(tw_version) >= Gem::Version.new(DEFAULT_TO_PUT_SAVER_FROM_VERSION)
  end

  # True if any non-default advanced settings are present
  def has_advanced_settings?
    return true if is_tw5? && use_put_saver? != default_to_put_saver?
    return true if allow_public_clone?
    return true if allow_in_iframe?
    false
  end

  def url
    Settings.subdomain_site_url(name)
  end

  def host
    Settings.subdomain_site_host(name)
  end

  def favicon_asset_name
    'favicon-green.ico'
  end

  def is_tspot?
    false
  end

  def deleted?
    false
  end

  def redirect_to
    nil
  end

  # If site history is enabled then keep many saves, otherwise keep just
  # a few. Users won't be able to see them (for now at least), but would
  # be nice if the save history is not entirely empty after subscribing.
  # See also app/jobs/prune_attachments_job.
  def keep_count
    return 100 if site_history_enabled?
    4
  end

  private

  def site_history_enabled?
    Settings.feature_enabled?(:site_history, user)
  end

end
