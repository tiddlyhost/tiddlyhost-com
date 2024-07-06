# frozen_string_literal: true

class GenerateThumbnailJob < ApplicationJob
  queue_as :default

  def perform(model_name, site_id)
    return unless (site = GenerateThumbnailJob.from_model_name_and_id(model_name, site_id))

    # If the thumbnail is new enough then no need to regenerate
    return if site.thumbnail_fresh?

    # Remove queued jobs that would regenerate the thumbnail we're about to create
    # (This might be ineffective if the worker loaded them already.)
    dupe_jobs(model_name, site_id).delete_all

    # Generate thumbnail
    site.send(:update_thumbnail_now)
  end

  def dupe_jobs(model_name, site_id)
    # This is hacky but I guess it works
    Delayed::Job
      .where('locked_by IS NULL')
      .where("handler like '%GenerateThumbnailJob\n%'")
      .where("handler like '%  - #{model_name}\n%'")
      .where("handler like '%  - #{site_id}\n%'")
  end

  # Help identify problematic sites
  def self.running_sites
    Delayed::Job.where.not(locked_by: nil).map do |j|
      j.handler.scan(/^  - (\S+)$/).flatten
    end.map do |model_name, site_id|
      from_model_name_and_id(model_name, site_id)
    end.compact
  end

  def self.from_model_name_and_id(model_name, site_id)
    return unless model_name.in?(%w[Site TspotSite])
    return unless (site = model_name.safe_constantize&.find_by_id(site_id))

    site
  end

  def max_run_time
    45.seconds
  end

  def max_attempts
    1
  end
end
