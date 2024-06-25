# frozen_string_literal: true

class AddUsernameToUsers < ActiveRecord::Migration[6.1]
  def change
    add_column :users, :username, :string, limit: 30
  end
end
