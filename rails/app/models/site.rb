class Site < ApplicationRecord
  include SiteCommon

  # The empty used when the site was created.
  # (It might not reflect what the site is now since the
  # user may have uploaded a different type of TiddlyWiki.)
  belongs_to :empty

  # The timestamps can be a few milliseconds apart, so that's why we need the interval
  # Todo: blob_created_at would be a more useful timestamp to use here than updated_at.
  scope :never_updated,         -> { where("AGE(sites.updated_at, sites.created_at) <= INTERVAL '0.5 SECOND'") }
  scope :updated_at_least_once, -> { where("AGE(sites.updated_at, sites.created_at) >  INTERVAL '0.5 SECOND'") }

  scope :for_hub, -> { searchable.updated_at_least_once }

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

  def looks_valid?
    th_file.looks_valid?
  end

  def html_content(signed_in_user: nil)
    th_file.apply_tiddlyhost_mods(name,
      signed_in_user: signed_in_user, enable_put_saver: enable_put_saver).to_html
  end

  def json_data(opts={})
    th_file.tiddlers_data(**opts)
  end

  def tiddler_data(tiddler_name)
    blob_cache(:tiddler_data, tiddler_name) do
      th_file.tiddler_data(tiddler_name)
    end
  end

  def download_content
    th_file.apply_tiddlyhost_mods(name, for_download: true).to_html
  end

  def show_advanced_settings?
    return true if new_record? && empty_id && empty_id != Empty.default_id
    return true if enable_put_saver? || allow_in_iframe?
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

end
