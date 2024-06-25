# frozen_string_literal: true

class AddAltSubscribedToUser < ActiveRecord::Migration[7.0]
  def change
    add_column :users, :alt_subscription, :string
  end
end
