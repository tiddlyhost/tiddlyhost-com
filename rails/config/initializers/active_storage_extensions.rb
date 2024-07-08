module ActiveStorageExtensions
  extend ActiveSupport::Concern

  included do
    has_one :attachment_label, foreign_key: :active_storage_attachments_id, dependent: :destroy

    def attachment_label=(value)
      value = AttachmentLabel.create(text: value) if value.is_a?(String)
      super
    end
  end
end

ActiveSupport.on_load(:active_storage_attachment) do
  include ActiveStorageExtensions
end
