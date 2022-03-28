
class HubHelperTest < ActionView::TestCase

  test "nice view count" do
    {
      123 => '123',
      1234 => '1.2K',
      1254 => '1.3K',
      12345 => '12K',
      123456 => '123K',

    }.each do |view_count, expected|
      assert_equal expected, nice_view_count(view_count)
    end
  end

end
