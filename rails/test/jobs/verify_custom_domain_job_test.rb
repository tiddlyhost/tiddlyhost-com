require 'test_helper'

class VerifyCustomDomainJobTest < ActiveSupport::TestCase
  setup do
    @site = sites(:mysite)
    @site.custom_domain&.destroy
    @custom_domain = CustomDomain.create!(site: @site, domain: 'test-verify.example.com')
  end

  test 'successful verification updates status to verified' do
    DnsVerifier.stubs(:check_txt_record).with(
      @custom_domain.verification_record_name,
      @custom_domain.verification_record_value
    ).returns({ success: true })

    VerifyCustomDomainJob.perform_now(@custom_domain.id)
    @custom_domain.reload

    assert @custom_domain.verified?
    assert_not_nil @custom_domain.verified_at
    assert_not_nil @custom_domain.last_verified_check_at
    assert_nil @custom_domain.last_error
  end

  test 'failed verification stores error and stays pending' do
    DnsVerifier.stubs(:check_txt_record).returns(
      { success: false, error: "No TXT record found at _tiddlyhost-verification.test-verify.example.com" }
    )

    VerifyCustomDomainJob.perform_now(@custom_domain.id)
    @custom_domain.reload

    assert @custom_domain.pending_verification?
    assert_nil @custom_domain.verified_at
    assert_not_nil @custom_domain.last_verified_check_at
    assert_equal "No TXT record found at _tiddlyhost-verification.test-verify.example.com", @custom_domain.last_error
  end

  test 'skips already verified domain' do
    @custom_domain.update!(status: :verified, verified_at: 1.hour.ago)

    DnsVerifier.expects(:check_txt_record).never

    VerifyCustomDomainJob.perform_now(@custom_domain.id)
  end

  test 'skips already active domain' do
    @custom_domain.update!(status: :active, verified_at: 1.hour.ago)

    DnsVerifier.expects(:check_txt_record).never

    VerifyCustomDomainJob.perform_now(@custom_domain.id)
  end

  test 'handles missing custom domain gracefully' do
    assert_nothing_raised do
      VerifyCustomDomainJob.perform_now(-1)
    end
  end

  test 'clears previous error on successful verification' do
    @custom_domain.update!(last_error: "Previous DNS error")

    DnsVerifier.stubs(:check_txt_record).returns({ success: true })

    VerifyCustomDomainJob.perform_now(@custom_domain.id)
    @custom_domain.reload

    assert @custom_domain.verified?
    assert_nil @custom_domain.last_error
  end
end
