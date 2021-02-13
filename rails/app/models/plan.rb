
class Plan < ApplicationRecord
  has_many :users

  def self.default
    self.find_by_name(Settings.default_plan_name)
  end

  def self.superuser
    self.find_by_name('superuser')
  end
end
