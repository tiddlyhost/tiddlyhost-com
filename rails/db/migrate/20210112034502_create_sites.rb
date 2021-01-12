class CreateSites < ActiveRecord::Migration[6.1]
  def change
    create_table :sites do |t|
      t.string :name
      t.boolean :is_private, default: false
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end
  end
end
