class User < ApplicationRecord
  # Include devise modules. Others available are:
  # :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :confirmable, :lockable, :timeoutable, :trackable

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
