class User < ApplicationRecord
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

  has_many :sites, dependent: :destroy
  belongs_to :plan
  validates_presence_of :name

  validates :username,
    uniqueness: {
      case_sensitive: false,
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

  def username_or_name
    username.presence || name
  end

  def has_plan?(plan_name)
    plan.name == plan_name.to_s
  end

  def has_username?
    username.present?
  end

  def has_hub_sites?
    sites.searchable.any?
  end

  def is_superuser?
    has_plan?(:superuser)
  end

  def is_admin?
    is_superuser?
  end

end
