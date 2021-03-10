require "test_helper"

class EmptyTest < ActiveSupport::TestCase

  test "default empty" do
    assert_equal Settings.default_empty_name, Empty.default.name
  end

end
