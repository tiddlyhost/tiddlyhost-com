class AttachmentLabel < ApplicationRecord
  belongs_to :active_storage_attachments, class_name: 'ActiveStorage::Attachment'

  def to_s = text
end
