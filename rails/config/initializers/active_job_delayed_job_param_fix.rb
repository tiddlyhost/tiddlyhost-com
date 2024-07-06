# frozen_string_literal: true

#
# Explanation: Because delayed job sees the job wrapper and not the actual
# underlying job, `payload_object.respond_to?(:max_attempts)` in
# Delayed::Backend::Base doesn't work like it is supposed to. This adds some
# methods to the wrapper so that delayed job workers can see those params
# defined in the job.
#
# Based on https://github.com/ajporterfield/activejob_dj_overrides/blob/master/lib/activejob_dj_overrides.rb
#
module ActiveJobDelayedJobParamFix
  def max_attempts
    return job.max_attempts if job.respond_to?(:max_attempts)
  end

  def max_run_time
    return job.max_run_time if job.respond_to?(:max_run_time)
  end

  private

  def job
    @job ||= ActiveJob::Base.deserialize(job_data)
  end
end

ActiveJob::QueueAdapters::DelayedJobAdapter::JobWrapper.include ActiveJobDelayedJobParamFix
