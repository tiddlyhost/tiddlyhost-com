require "test_helper"

class UserTest < ActiveSupport::TestCase

  setup do
    @user = users(:bobby)
  end

  test "user plans" do
    assert_equal 'basic', @user.plan.name
  end
end
