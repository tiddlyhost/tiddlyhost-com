class VerifyCustomDomainJob < ApplicationJob
  queue_as :default

  def perform(custom_domain_id)
    custom_domain = CustomDomain.find_by(id: custom_domain_id)
    return unless custom_domain
    return if custom_domain.verified? || custom_domain.active?

    result = DnsVerifier.check_txt_record(
      custom_domain.verification_record_name,
      custom_domain.verification_record_value
    )

    if result[:success]
      custom_domain.update!(
        status: :verified,
        verified_at: Time.current,
        last_verified_check_at: Time.current,
        last_error: nil
      )
    else
      custom_domain.update!(
        last_verified_check_at: Time.current,
        last_error: result[:error]
      )
    end
  end
end
