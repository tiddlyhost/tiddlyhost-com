require 'test_helper'

class CustomDomainTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  setup do
    @site = sites(:mysite)
    @custom_domain = CustomDomain.new(
      site: @site,
      domain: 'example.com'
    )
  end

  test 'valid custom domain' do
    assert @custom_domain.valid?
  end

  test 'domain is required' do
    @custom_domain.domain = nil
    refute @custom_domain.valid?
    assert_includes @custom_domain.errors[:domain], "can't be blank"
  end

  test 'domain must be unique' do
    @custom_domain.save!
    another_site = Site.create!(name: 'another-site', user: @site.user, empty: @site.empty)
    duplicate = CustomDomain.new(site: another_site, domain: 'example.com')
    refute duplicate.valid?
    assert_includes duplicate.errors[:domain], "has already been taken"
  end

  test 'domain normalization downcases domain' do
    @custom_domain.domain = 'EXAMPLE.COM'
    @custom_domain.valid?
    assert_equal 'example.com', @custom_domain.domain
  end

  test 'domain normalization strips whitespace' do
    @custom_domain.domain = '  example.com  '
    @custom_domain.valid?
    assert_equal 'example.com', @custom_domain.domain
  end

  test 'domain format validation' do
    # Valid domains
    [
      'example.com',
      'sub.example.com',
      'my-site.example.com',
      'a.b.c.example.com',
      '123.example.com',
    ].each do |valid_domain|
      @custom_domain.domain = valid_domain
      assert @custom_domain.valid?, "#{valid_domain} should be valid"
    end

    # Invalid domains
    [
      'example',           # no TLD
      '-example.com',      # starts with dash
      'example-.com',      # ends with dash
      'exam ple.com',      # contains space
      'example..com',      # double dot
      '.example.com',      # starts with dot
      'example.com.',      # ends with dot
    ].each do |invalid_domain|
      @custom_domain.domain = invalid_domain
      refute @custom_domain.valid?, "#{invalid_domain} should be invalid"
    end
  end

  test 'blocks exact reserved domains' do
    ['tiddlyhost.com', 'tiddlyspot.com', 'localhost'].each do |reserved|
      @custom_domain.domain = reserved
      refute @custom_domain.valid?
      assert_includes @custom_domain.errors[:domain], "cannot use reserved domains or their subdomains"
    end
  end

  test 'blocks subdomains of reserved domains' do
    [
      'www.tiddlyhost.com',
      'admin.tiddlyhost.com',
      'api.tiddlyhost.com',
      'foo.tiddlyspot.com',
      'bar.baz.tiddlyhost.com',
    ].each do |reserved_subdomain|
      @custom_domain.domain = reserved_subdomain
      refute @custom_domain.valid?, "#{reserved_subdomain} should be blocked"
      assert_includes @custom_domain.errors[:domain], "cannot use reserved domains or their subdomains"
    end
  end

  test 'allows domains containing reserved words but not as subdomain' do
    # These should be allowed since they're not subdomains
    [
      'tiddlyhostfan.com',
      'mytiddlyhost.org',
    ].each do |allowed_domain|
      @custom_domain.domain = allowed_domain
      assert @custom_domain.valid?, "#{allowed_domain} should be allowed"
    end
  end

  test 'generates verification token on create' do
    assert_nil @custom_domain.verification_token
    @custom_domain.save!
    assert_not_nil @custom_domain.verification_token
    assert_equal 32, @custom_domain.verification_token.length # hex(16) = 32 chars
  end

  test 'default status is pending_verification' do
    @custom_domain.save!
    assert @custom_domain.pending_verification?
    assert_equal 0, @custom_domain.status_before_type_cast
  end

  test 'default ssl_status is pending' do
    @custom_domain.save!
    assert @custom_domain.ssl_pending?
    assert_equal 0, @custom_domain.ssl_status_before_type_cast
  end

  test 'status enum states' do
    @custom_domain.save!

    @custom_domain.pending_verification!
    assert @custom_domain.pending_verification?

    @custom_domain.verified!
    assert @custom_domain.verified?

    @custom_domain.active!
    assert @custom_domain.active?

    @custom_domain.failed!
    assert @custom_domain.failed?
  end

  test 'ssl_status enum states with prefix' do
    @custom_domain.save!

    @custom_domain.ssl_pending!
    assert @custom_domain.ssl_pending?

    @custom_domain.ssl_issued!
    assert @custom_domain.ssl_issued?

    @custom_domain.ssl_expired!
    assert @custom_domain.ssl_expired?

    @custom_domain.ssl_failed!
    assert @custom_domain.ssl_failed?
  end

  test 'fully_active? requires both active status and issued SSL' do
    @custom_domain.save!

    # Not active yet
    @custom_domain.pending_verification!
    @custom_domain.ssl_pending!
    refute @custom_domain.fully_active?

    # Active but no SSL
    @custom_domain.active!
    @custom_domain.ssl_pending!
    refute @custom_domain.fully_active?

    # SSL issued but not active
    @custom_domain.verified!
    @custom_domain.ssl_issued!
    refute @custom_domain.fully_active?

    # Both active and SSL issued
    @custom_domain.active!
    @custom_domain.ssl_issued!
    assert @custom_domain.fully_active?
  end

  test 'fully_active scope' do
    @custom_domain.save!

    # Create additional sites for testing (one site = one custom domain)
    pending_site = Site.create!(name: 'pending-site', user: @site.user, empty: @site.empty)
    active_site = Site.create!(name: 'active-site', user: @site.user, empty: @site.empty)

    pending_domain = CustomDomain.create!(site: pending_site, domain: 'pending.com')
    active_domain = CustomDomain.create!(
      site: active_site,
      domain: 'active.com',
      status: :active,
      ssl_status: :issued
    )

    fully_active_domains = CustomDomain.fully_active
    assert_includes fully_active_domains, active_domain
    refute_includes fully_active_domains, pending_domain
    refute_includes fully_active_domains, @custom_domain
  end

  test 'expiring_soon scope only includes issued certificates' do
    @custom_domain.save!

    # Create additional sites for testing (one site = one custom domain)
    expiring_site = Site.create!(name: 'expiring-site', user: @site.user, empty: @site.empty)
    safe_site = Site.create!(name: 'safe-site', user: @site.user, empty: @site.empty)
    pending_site = Site.create!(name: 'pending-cert-site', user: @site.user, empty: @site.empty)

    # Create domains with different SSL states
    expired_soon = CustomDomain.create!(
      site: expiring_site,
      domain: 'expires-soon.com',
      ssl_status: :issued,
      ssl_expires_at: 15.days.from_now
    )

    not_expiring = CustomDomain.create!(
      site: safe_site,
      domain: 'not-expiring.com',
      ssl_status: :issued,
      ssl_expires_at: 60.days.from_now
    )

    pending_cert = CustomDomain.create!(
      site: pending_site,
      domain: 'pending-cert.com',
      ssl_status: :pending,
      ssl_expires_at: 15.days.from_now
    )

    expiring = CustomDomain.expiring_soon
    assert_includes expiring, expired_soon
    refute_includes expiring, not_expiring
    refute_includes expiring, pending_cert
  end

  test 'verification_record_name' do
    @custom_domain.domain = 'example.com'
    assert_equal '_tiddlyhost-verification.example.com', @custom_domain.verification_record_name
  end

  test 'verification_record_value returns token' do
    @custom_domain.save!
    assert_equal @custom_domain.verification_token, @custom_domain.verification_record_value
  end

  test 'dns_verification_instructions contains key information' do
    @custom_domain.save!
    instructions = @custom_domain.dns_verification_instructions

    assert_includes instructions, @custom_domain.verification_record_name
    assert_includes instructions, @custom_domain.verification_token
    assert_includes instructions, 'TXT'
    assert_includes instructions, 'Verify Domain'
  end

  test 'verification subdomain constant is available for UI' do
    assert_equal '_tiddlyhost-verification', CustomDomain::VERIFICATION_SUBDOMAIN
  end

  test 'belongs to site' do
    assert_equal @site, @custom_domain.site
  end

  test 'site can only have one custom domain' do
    @custom_domain.save!

    second_domain = CustomDomain.new(site: @site, domain: 'another.com')
    refute second_domain.valid?
    assert_includes second_domain.errors[:site_id], "has already been taken"
  end

  test 'custom domain is destroyed when site is destroyed' do
    @custom_domain.save!
    assert_difference 'CustomDomain.count', -1 do
      @site.destroy
    end
  end

  test 'verify_now! enqueues verification job' do
    @custom_domain.save!
    assert_enqueued_with(job: VerifyCustomDomainJob, args: [@custom_domain.id]) do
      @custom_domain.verify_now!
    end
  end

  test 'check_all_pending enqueues sweep job' do
    assert_enqueued_with(job: CheckPendingDomainsJob) do
      CustomDomain.check_all_pending
    end
  end

  test 'mark_ssl_issued! sets ssl attributes' do
    @custom_domain.save!
    @custom_domain.verified!
    @custom_domain.mark_ssl_issued!
    @custom_domain.reload

    assert @custom_domain.ssl_issued?
    assert_not_nil @custom_domain.ssl_issued_at
    assert_not_nil @custom_domain.ssl_expires_at
    assert_not_nil @custom_domain.certificate_renewal_attempted_at
    assert_nil @custom_domain.last_error
    assert_in_delta 90.days.from_now, @custom_domain.ssl_expires_at, 5.seconds
  end

  test 'mark_ssl_issued! clears previous error' do
    @custom_domain.save!
    @custom_domain.update!(status: :verified, last_error: 'previous error')
    @custom_domain.mark_ssl_issued!
    @custom_domain.reload

    assert_nil @custom_domain.last_error
  end

  test 'mark_ssl_failed! stores error message' do
    @custom_domain.save!
    @custom_domain.verified!
    @custom_domain.mark_ssl_failed!('certbot timeout')
    @custom_domain.reload

    assert @custom_domain.ssl_failed?
    assert_equal 'certbot timeout', @custom_domain.last_error
    assert_not_nil @custom_domain.certificate_renewal_attempted_at
  end

  test 'needs_ssl_certificate scope returns verified domains with pending or failed ssl' do
    @custom_domain.save!

    pending_ssl_site = Site.create!(name: 'pending-ssl', user: @site.user, empty: @site.empty)
    failed_ssl_site = Site.create!(name: 'failed-ssl', user: @site.user, empty: @site.empty)
    issued_ssl_site = Site.create!(name: 'issued-ssl', user: @site.user, empty: @site.empty)
    unverified_site = Site.create!(name: 'unverified', user: @site.user, empty: @site.empty)

    pending_ssl = CustomDomain.create!(site: pending_ssl_site, domain: 'pending-ssl.com', status: :verified, ssl_status: :pending)
    failed_ssl = CustomDomain.create!(site: failed_ssl_site, domain: 'failed-ssl.com', status: :verified, ssl_status: :failed)
    issued_ssl = CustomDomain.create!(site: issued_ssl_site, domain: 'issued-ssl.com', status: :verified, ssl_status: :issued)
    unverified = CustomDomain.create!(site: unverified_site, domain: 'unverified.com', status: :pending_verification, ssl_status: :pending)

    needs_cert = CustomDomain.needs_ssl_certificate
    assert_includes needs_cert, pending_ssl
    assert_includes needs_cert, failed_ssl
    refute_includes needs_cert, issued_ssl
    refute_includes needs_cert, unverified
    refute_includes needs_cert, @custom_domain
  end
end
