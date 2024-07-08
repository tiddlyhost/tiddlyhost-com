class UpdatePaySchema < ActiveRecord::Migration[7.0]
  #
  # Produced this by looking at the diff between the old
  # migration here in this repo and the migration in pay-6.3.1
  #
  def change
    add_column :pay_subscriptions, :current_period_start, :datetime
    add_column :pay_subscriptions, :current_period_end, :datetime

    add_column :pay_subscriptions, :metered, :boolean
    add_column :pay_subscriptions, :pause_behavior, :string
    add_column :pay_subscriptions, :pause_starts_at, :datetime
    add_column :pay_subscriptions, :pause_resumes_at, :datetime

    add_index :pay_subscriptions, [:metered]
    add_index :pay_subscriptions, [:pause_starts_at]
  end
end
