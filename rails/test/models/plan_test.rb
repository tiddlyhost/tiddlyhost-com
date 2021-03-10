require "test_helper"

class PlanTest < ActiveSupport::TestCase

  test "default plan" do
    assert_equal Settings.default_plan_name, Plan.default.name
  end

end
