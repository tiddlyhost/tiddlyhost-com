# frozen_string_literal: true

require "test_helper"

class UserTypeTest < ActiveSupport::TestCase

  test "default user type" do
    assert_equal Settings.default_user_type_name, UserType.default.name
  end

end
