# frozen_string_literal: true

class PruneAttachmentsJob < ApplicationJob
  queue_as :default

  def perform(model_name, site_id)
    return unless model_name.in?(%w[ Site TspotSite ])

    model_name.safe_constantize&.find_by_id(site_id)&.send(:prune_attachments_now)
  end
end
