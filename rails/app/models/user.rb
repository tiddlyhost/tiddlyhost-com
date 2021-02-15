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

  def has_plan?(plan_name)
    plan.name == plan_name.to_s
  end

  def is_superuser?
    has_plan?(:superuser)
  end

  def is_admin?
    is_superuser?
  end

end
