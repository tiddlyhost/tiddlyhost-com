class CustomDomain < ApplicationRecord
  belongs_to :site

  validates :site_id, uniqueness: true
  validates :domain, presence: true, uniqueness: true, format: { with: /\A[a-z0-9]([a-z0-9-]*[a-z0-9])?(\.[a-z0-9]([a-z0-9-]*[a-z0-9])?)+\z/ }
  validate :not_reserved_domain

  enum :status, { pending_verification: 0, verified: 1, active: 2, failed: 3 }, default: :pending_verification
  enum :ssl_status, { pending: 0, issued: 1, expired: 2, failed: 3 }, prefix: :ssl, default: :pending

  scope :expiring_soon, -> { where(ssl_status: :issued).where('ssl_expires_at < ?', 30.days.from_now) }
  scope :fully_active, -> { where(status: :active, ssl_status: :issued) }
  scope :needs_ssl_certificate, -> { where(status: :verified).where(ssl_status: [:pending, :failed]) }

  before_validation :normalize_domain
  before_create :generate_verification_token

  # Check if domain is fully active (verified and has valid SSL)
  def fully_active?
    active? && ssl_issued?
  end

  VERIFICATION_SUBDOMAIN = '_tiddlyhost-verification'

  # DNS TXT record name for verification
  def verification_record_name
    "#{VERIFICATION_SUBDOMAIN}.#{domain}"
  end

  # DNS TXT record value for verification
  def verification_record_value
    verification_token
  end

  # Human-readable DNS verification instructions
  def dns_verification_instructions
    <<~INSTRUCTIONS
      To verify ownership of your domain, add this DNS TXT record:

      Name:  #{verification_record_name}
      Type:  TXT
      Value: #{verification_record_value}

      Note: Some DNS providers automatically append your domain name.
      If so, use just #{VERIFICATION_SUBDOMAIN} as the name.

      After adding the record, click "Verify Domain" to continue.
      DNS changes can take a few minutes to propagate.
    INSTRUCTIONS
  end

  def mark_ssl_issued!
    update!(
      ssl_status: :issued,
      ssl_issued_at: Time.current,
      ssl_expires_at: 90.days.from_now,
      certificate_renewal_attempted_at: Time.current,
      last_error: nil
    )
  end

  def mark_ssl_failed!(error_message)
    update!(
      ssl_status: :failed,
      certificate_renewal_attempted_at: Time.current,
      last_error: error_message
    )
  end

  def mark_active!
    update!(status: :active)
  end

  def verify_now!
    VerifyCustomDomainJob.perform_later(id)
  end

  def self.check_all_pending
    CheckPendingDomainsJob.perform_later
  end

  private

  def normalize_domain
    self.domain = domain.downcase.strip if domain.present?
  end

  def not_reserved_domain
    return if domain.blank?

    reserved_domains = ['tiddlyhost.com', 'tiddlyspot.com', 'localhost']
    reserved_patterns = [/\.tiddlyhost\.com\z/, /\.tiddlyspot\.com\z/]

    if reserved_domains.include?(domain) || reserved_patterns.any? { |pattern| domain.match?(pattern) }
      errors.add(:domain, "cannot use reserved domains or their subdomains")
    end
  end

  def generate_verification_token
    self.verification_token = SecureRandom.hex(16)
  end
end
