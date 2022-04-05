require "test_helper"

class EmptyTest < ActiveSupport::TestCase

  test "default empty" do
    assert_equal Settings.default_empty_name, Empty.default.name
  end

  test "is_default method" do
    assert Empty.default.is_default?
    assert_not Empty.last.is_default?
  end

  test "empty file present" do
    empty = Empty.find_by_name('classic')
    assert empty.present?

    # Since there's no foobar.html in the empties dir...
    empty.update(name: 'foobar')
    refute empty.present?
  end

end
