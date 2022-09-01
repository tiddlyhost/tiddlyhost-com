
class GenerateThumbnailJob < ApplicationJob
  queue_as :default

  def perform(model_name, site_id)
    return unless model_name.in?(%w[ Site TspotSite ])
    model_name.safe_constantize&.find_by_id(site_id)&.send(:update_thumbnail_now)
    # Todo: Clear out any other queued jobs for the same site
  end

end
