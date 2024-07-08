class CreateAttachmentLabels < ActiveRecord::Migration[7.1]
  def change
    create_table :attachment_labels do |t|
      t.string :text
      t.references :active_storage_attachments, null: false
    end
  end
end
