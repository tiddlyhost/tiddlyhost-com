
class GenerateThumbnailJob < ApplicationJob
  queue_as :default

  def perform(site_id)
    Site.find_by_id(site_id)&.send(:update_thumbnail_now)
    # Todo: Clear out any other queued jobs for the same site
  end

end
