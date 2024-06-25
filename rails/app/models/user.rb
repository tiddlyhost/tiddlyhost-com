# frozen_string_literal: true

class User < ApplicationRecord
  include AdminSearchable
  include Subscriber

  #
  # Include devise modules. Others available are:
  # :omniauthable
  #
  # Using :secure_validatable from devise-security instead of
  # :validateable from standard devise, but with email_validation
  # turned off.
  #
  # There are also some other modules in devise-security that
  # we're not using.
  #
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable,
         :confirmable, :lockable, :timeoutable, :trackable,
         :secure_validatable, email_validation: false

  belongs_to :user_type

  validates_presence_of :name

  has_many :sites, dependent: :destroy
  has_many :tspot_sites, dependent: :nullify

  def all_sites
    return sites unless Settings.tiddlyspot_enabled?
    sites + tspot_sites
  end

  validates :username,
    uniqueness: {
      case_sensitive: false,
      allow_blank: true,
    },
    length: {
      minimum: 3,
      maximum: 30,
      allow_blank: true,
    },
    format: {
      # Must be upper- or lowercase letters, numerals, and dashes
      # Must not have more than one consecutive dash
      # Must not start or end with a dash
      # (See also app/javascript/packs/application.js)
      without: / [^A-Za-z0-9-] | -- | ^- | -$ /x,
      message: "'%{value}' is not allowed. Please choose a different username.",
    }

  scope :signed_in_never,          ->        { where(sign_in_count: 0) }
  scope :signed_in_once,           ->        { where(sign_in_count: 1) }
  scope :signed_in_more_than,      ->(times) { where('sign_in_count > ?', times) }
  scope :signed_in_more_than_once, ->        { signed_in_more_than(1) }
  scope :signed_in_since,          ->(time)  { where('current_sign_in_at >= ?', time) }
  scope :active_day,               ->        { signed_in_since(1.day.ago) }
  scope :active_week,              ->        { signed_in_since(1.week.ago) }
  scope :active_month,             ->        { signed_in_since(1.month.ago) }

  def username_or_name
    username.presence || name
  end

  def username_or_email
    username.presence || email
  end

  def short_name
    name.split(/\s+/).first
  end

  def email_change_in_progress?
    unconfirmed_email.present?
  end

  # Unused. Delete maybe?
  scope :with_type,    ->(*type_names) { where(    user_type_id: UserType.where(name: type_names.map(&:to_s)).pluck(:id)) }
  scope :without_type, ->(*type_names) { where.not(user_type_id: UserType.where(name: type_names.map(&:to_s)).pluck(:id)) }

  scope :search_for, ->(search_text) {
    where("#{table_name}.name ILIKE CONCAT('%',?,'%')", search_text).
    or(where("#{table_name}.username ILIKE CONCAT('%',?,'%')", search_text)).
    or(where("#{table_name}.email ILIKE CONCAT('%',?,'%')", search_text)) }

  # Not sure if we could use an assocation here or at least some clever joins, but this seems to work okay
  def site_attachments
    ActiveStorage::Attachment.where(record_id: sites.pluck(:id), record_type: 'Site')
  end

  def site_blobs
    ActiveStorage::Blob.where(id: site_attachments.pluck(:blob_id))
  end

  def total_storage_bytes
    site_blobs.sum(:byte_size)
  end

  def has_user_type?(user_type_name)
    user_type.name == user_type_name.to_s
  end

  def has_username?
    username.present?
  end

  def hub_sites_count
    sites.for_hub.count + tspot_sites.for_hub.count
  end

  def has_hub_sites?
    hub_sites_count > 0
  end

  def has_hub_link?
    has_hub_sites? && has_username?
  end

  def is_superuser?
    has_user_type?(:superuser)
  end

  def is_admin?
    is_superuser?
  end

  def use_avatar?
    use_gravatar? || use_libravatar?
  end

  def is_tiddlyhost?
    email == Settings.tiddlyhost_account_email
  end

  # The default is set in config/initializers/devise
  def timeout_in
    return 12.hours if is_admin?
    super
  end

  # https://www.rubydoc.info/github/plataformatec/devise/Devise/Models/Confirmable#after_confirmation-instance_method
  def after_confirmation
    th_log("Account #{id} #{email} confirmation")
  end

end
