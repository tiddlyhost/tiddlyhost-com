class AddPlans < ActiveRecord::Migration[6.1]
  def change
    create_table :plans do |t|
      t.string :name
    end

    add_reference :users, :plan, foreign_key: true
  end
end
