
class TspotSite < ApplicationRecord
  # We need to tweak the validations a little so disable the default validations.
  # See lib/active_model/secure_password.rb in the active_model gem.
  has_secure_password :password, validations: false

  # This is the same as one of the default validations
  validates_confirmation_of :password, allow_blank: true

  # This one is different. The allow_nil is added so we can update
  # sites with legacy passwords.
  validates_length_of :password, allow_nil: true,
    maximum: ActiveModel::SecurePassword::MAX_PASSWORD_LENGTH_ALLOWED,
    minimum: 6

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
      created_ip: ip_address&.to_s,
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
    find_by_name(site_name)&.ensure_destubbed(ip_address)
  end

  def use_legacy_password?
    password_digest.blank?
  end

  def passwd_ok?(user, pass)
    if use_legacy_password?
      TspotFetcher.passwd_match?(user, pass, htpasswd)
    else
      user == name && authenticate(pass)
    end
  end

  # Don't write to the legacy password. Instead create a new
  # one using the standard rails functionality. It should write
  # the digest to the password_digest field.
  #
  # Throws an exception if there's a problem.
  #
  def set_password(new_password, new_password_confirmation)
    original_digest = password_digest

    begin
      self.password = new_password
      self.password_confirmation = new_password_confirmation
      self.save!
    rescue ActiveRecord::RecordInvalid
      # Reset the password_digest field so the existing password keeps working
      update(password_digest: original_digest)
      raise
    end
  end

  def show_advanced_settings?
    return true if allow_in_iframe?
    false
  end

  def url
    Settings.tiddlyspot_site_url(name)
  end

  def host
    Settings.tiddlyspot_site_host(name)
  end

  def favicon_asset_name
    'favicon-tiddlyspot.ico'
  end

end
