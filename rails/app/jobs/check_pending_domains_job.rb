class CheckPendingDomainsJob < ApplicationJob
  queue_as :default

  RECHECK_INTERVAL = 10.minutes
  ABANDON_AFTER = 72.hours

  def perform
    CustomDomain.
      where(status: [:pending_verification, :verification_requested]).
      where(created_at: ABANDON_AFTER.ago..).
      where(last_verified_check_at: [nil, ..RECHECK_INTERVAL.ago]).
      find_each do |custom_domain|
        VerifyCustomDomainJob.perform_later(custom_domain.id)
      end
  end
end
