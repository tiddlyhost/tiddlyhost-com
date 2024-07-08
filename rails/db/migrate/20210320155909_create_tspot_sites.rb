class CreateTspotSites < ActiveRecord::Migration[6.1]
  def change
    create_table :tspot_sites do |t|
      t.string :name
      t.boolean :exists
      t.boolean :is_private
      t.boolean :is_searchable
      t.string :htpasswd
      t.string :description

      t.datetime :accessed_at
      t.integer :access_count, default: 0
      t.integer :save_count, default: 0

      t.references :user, null: true, foreign_key: true

      t.timestamps
    end

    add_index :tspot_sites, :name, unique: true
  end
end
