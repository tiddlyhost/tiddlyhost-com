class RenameUserPlan < ActiveRecord::Migration[7.0]
  def change
    rename_table :plans, :user_types
    rename_column :users, :plan_id, :user_type_id

    # The "basic" user type should have id 1
    change_column_default :users, :user_type_id, 1
  end
end
