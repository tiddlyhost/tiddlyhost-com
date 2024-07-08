require 'test_helper'

class AttachmentLabelTest < ActiveSupport::TestCase
  setup do
    # Prepare a site with one saved version
    @site = Site.find_by_name('mysite')
    @site.content_upload('some content')
    @file = @site.saved_content_files.first
  end

  def assert_count_change(difference, &)
    assert_difference('AttachmentLabel.count', difference, &)
  end

  def assert_created(&) = assert_count_change(1, &)
  def assert_deleted(&) = assert_count_change(-1, &)
  def assert_no_change(&) = assert_count_change(0, &)

  test 'create' do
    assert_nil @file.attachment_label

    # Add a label
    assert_created { @file.attachment_label = AttachmentLabel.create(text: 'foo') }
    assert_equal 'foo', @file.attachment_label.to_s

    # There's no change because there can be only one label at a time
    assert_no_change { @file.attachment_label = AttachmentLabel.create(text: 'bar') }
    assert_equal 'bar', @file.attachment_label.to_s
  end

  test 'create with convenience assignment method' do
    @file.attachment_label = 'foo'
    assert_equal 'foo', @file.attachment_label.to_s
  end

  test 'delete' do
    assert_created { @file.attachment_label = AttachmentLabel.create(text: 'foo') }
    assert_deleted { @file.attachment_label = nil }
    assert_nil @file.attachment_label
  end

  # Removing the attachment should clean up the label as well
  test 'cascade destroy' do
    assert_created { @file.attachment_label = AttachmentLabel.create(text: 'foo') }
    assert_deleted { @file.destroy }
  end
end
