class TspotSite < ApplicationRecord
  # We need to tweak the validations a little so disable the default validations.
  # See lib/active_model/secure_password.rb in the active_model gem.
  has_secure_password :password, validations: false

  # This is the same as one of the default validations
  validates_confirmation_of :password, allow_blank: true

  validates :redirect_to_url, url: { allow_blank: true }

  # This one is different. The allow_nil is added so we can update
  # sites with legacy passwords.
  validates_length_of :password, allow_nil: true,
    maximum: ActiveModel::SecurePassword::MAX_PASSWORD_LENGTH_ALLOWED,
    minimum: 6

  include SiteCommon

  # Will be nil mostly. (Has no foreign key constraint.)
  belongs_to :redirect_to_site, optional: true, class_name: 'Site'

  # Some duck typing for hub rendering
  alias_attribute :view_count, :access_count

  scope :owned, -> { where.not(user_id: nil) }
  scope :for_hub, -> { searchable.owned }

  # No tspot sites can be templates
  scope :templates_only, -> { where('1 = 2') }

  scope :no_stubs, -> { where.not(htpasswd: nil) }
  scope :stubs, -> { where(htpasswd: nil) }

  scope :not_deleted, -> { where(deleted: false) }

  # Legacy fetcher functionality has been removed since the S3 bucket
  # is no longer available. Sites can no longer be "destubbed" from
  # external sources.

  def html_content
    # We'll be removing TspotSites without a blob soon, at which
    # point this should not be needed
    return "" unless blob

    file_download
  end

  alias_method :download_content, :html_content

  # There's no populating any more. Will rename this method in future.
  # Return nil if the tspot site doesn't exist or if there is a record
  # for it but it has no content.
  #
  def self.find_and_populate(site_name)
    site = not_deleted.find_by_name(site_name)
    return nil unless site&.blob

    site
  end

  def use_legacy_password?
    password_digest.blank?
  end

  def passwd_ok?(user, pass)
    if use_legacy_password?
      self.class.passwd_match?(user, pass, htpasswd)
    else
      user == name && authenticate(pass)
    end
  end

  # Legacy password authentication
  def self.passwd_match?(given_username, given_passwd, htpasswd)
    return false unless
      given_username.present? && given_passwd.present? && htpasswd.present?

    username, passwd_crypt = htpasswd.split(':')
    salt = username[0, 2]
    given_username == username && given_passwd.crypt(salt) == passwd_crypt
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

  def clonable_by_user?(_)
    false
  end

  def cloneable_by_public?
    false
  end

  def cloned_from
    nil
  end

  # True if any non-default advanced settings are present
  def has_advanced_settings?
    return true if allow_in_iframe?
    return true if redirect_to_url.present?
    return true if redirect_to_site_id.present?

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

  def is_tspot?
    true
  end

  def redirect_to
    if redirect_to_site.present?
      redirect_to_site.url

    elsif redirect_tspot_to_url_enabled? && redirect_to_url.present?
      redirect_to_url

    end
  end

  # Todo: define this dynamically
  def redirect_tspot_to_url_enabled?
    Settings.feature_enabled?(:redirect_tspot_to_url, user)
  end

  # For legacy Tiddlyspot sites we don't provide the site history
  # feature, but let's one keep some previous versions so we can
  # help users recover from a broken save.
  def keep_count
    Settings.keep_counts[:tiddlyspot]
  end
end
