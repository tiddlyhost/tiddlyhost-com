
class TspotSite < ApplicationRecord
  include SiteCommon

  # Some duck typing for hub rendering
  alias_attribute :view_count, :access_count

  scope :owned, -> { where.not(user_id: nil) }
  scope :for_hub, -> { searchable.owned }

  scope :no_stubs, -> { where.not(htpasswd: nil) }
  scope :stubs, -> { where(htpasswd: nil) }

  # The TspotFetcher class knows how to fetch a site from the
  # dreamhost bucket. It can also determine if the site is public
  # or private, and can fetch the htpasswd file for auth checks.
  #
  def fetcher
    @_fetcher ||= TspotFetcher.new(name)
  end

  def fetcher=(fetcher)
    @_fetcher = fetcher
  end

  def html_content
    if blob
      file_download

    else
      # In case the site's content has never been saved.
      # (Probably not needed any more.)
      fetched_html

    end
  end

  def fetched_html
    site_cache(:fetched_html) do
      logger.info "  TspotSite fetch for #{name}"
      fetcher.html_file
    end
  end

  # Take the original Tiddlyspot site html and save it to a blob if it hasn't
  # been done already. I used it to bulk migrate all unmigrated tspots.
  # (Probably not useful any more since all tspot sites are now migrated.)
  #
  def ensure_migrated
    return if blob

    content_upload(fetcher.html_file)
  end

  # If we never fetched the site's details then htpasswd will be
  # nil. Let's call that a "stub".
  #
  def is_stub?
    htpasswd.blank?
  end

  def self.fetched_site_to_attrs(fetched_site, ip_address=nil)
    {
      name: fetched_site.name,
      is_private: fetched_site.is_private?,
      htpasswd: fetched_site.htpasswd_file,
      tiddlywiki_file: SiteCommon.attachable_hash(fetched_site.html_file),
      created_ip: ip_address.try(:to_s),
    }
  end

  def fetcher_attrs
    TspotSite.fetched_site_to_attrs(fetcher)
  end

  def ensure_destubbed(ip_address=nil)
    return self unless is_stub?
    update(fetcher_attrs)
    self
  end

  # Returns nil if the tspot site doesn't exist.
  # Because we populated all known tspot sites in the database we
  # no longer create a new record here, but we might need to use
  # the fetcher to populate its content and metadata.
  #
  def self.find_and_populate(site_name, ip_address=nil)
    find_by_name(site_name).try(:ensure_destubbed, ip_address)
  end

  def passwd_ok?(user, pass)
    TspotFetcher.passwd_match?(user, pass, htpasswd)
  end

  def url
    Settings.tiddlyspot_site_url(name)
  end

  def favicon_asset_name
    'favicon-tiddlyspot.ico'
  end

end
