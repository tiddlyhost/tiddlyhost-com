class PopulatePlans < ActiveRecord::Migration[6.1]

  def up
    # We'll start with two plans
    Plan.create!([
      {name: 'basic'},
      {name: 'superuser'}
    ])

    # Give everyone the default plan
    User.update_all(plan_id: Plan.default.id)

    # Make it the default
    change_column_default :users, :plan_id, Plan.default.id
  end

  def down
    change_column_default :users, :plan_id, nil
    User.update_all(plan_id: nil)
    Plan.delete_all
  end

end
