# frozen_string_literal: true

class UserType < ApplicationRecord
  include WithDefault

  has_many :users

  def self.superuser
    self.find_by_name('superuser')
  end
end
