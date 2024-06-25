# frozen_string_literal: true

class AddCloneCount < ActiveRecord::Migration[6.1]
  def change
    add_column :sites, :clone_count, :integer, default: 0
  end
end
