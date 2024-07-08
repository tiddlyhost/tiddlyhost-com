class AddUseLibravatarToUsers < ActiveRecord::Migration[7.0]
  def change
    add_column :users, :use_libravatar, :boolean, default: false
  end
end
