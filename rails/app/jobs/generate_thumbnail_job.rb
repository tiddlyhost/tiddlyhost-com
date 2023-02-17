
class GenerateThumbnailJob < ApplicationJob
  queue_as :default

  def perform(model_name, site_id)
    return unless model_name.in?(%w[ Site TspotSite ])
    return unless site = model_name.safe_constantize&.find_by_id(site_id)
    dupe_jobs(model_name, site_id).delete_all
    site.send(:update_thumbnail_now)
  end

  def dupe_jobs(model_name, site_id)
    # This is hacky but I guess it works
    Delayed::Job.
      where("locked_by IS NULL").
      where("handler like '%GenerateThumbnailJob\n%'").
      where("handler like '%  - #{model_name}\n%'").
      where("handler like '%  - #{site_id}\n%'")
  end

  def max_run_time
    45.seconds
  end

  def max_attempts
    1
  end

end
