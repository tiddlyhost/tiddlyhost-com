class AddUseGravatarToUser < ActiveRecord::Migration[6.1]
  def change
    add_column :users, :use_gravatar, :boolean, default: false
  end
end
