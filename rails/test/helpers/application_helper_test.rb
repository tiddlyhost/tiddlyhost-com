require 'test_helper'

class ApplicationHelperTest < ActionView::TestCase
  test 'nice view count' do
    {
      123 => '123',
      1234 => '1.2K',
      1254 => '1.3K',
      12_345 => '12K',
      123_456 => '120K',

    }.each do |view_count, expected|
      assert_equal expected, nice_view_count(view_count)
    end
  end

  test 'nice byte count' do
    # (I guess it uses 1024 instead of 1000)
    {
      123 => '123',
      1234 => '1.21 KB',
      12_345 => '12.1 KB',
      123_456 => '121 KB',
      123_456_789 => '118 MB',

    }.each do |view_count, expected|
      assert_equal expected, nice_byte_count(view_count)
    end
  end
end
