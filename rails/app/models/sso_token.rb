class SsoToken
  VERIFIER = Rails.application.message_verifier(:sso)
  EXPIRES_IN = 1.minute

  def self.generate(user_id:, domain:, return_to: "/")
    VERIFIER.generate(
      { user_id: user_id, domain: domain, return_to: return_to },
      purpose: :sso_login, expires_in: EXPIRES_IN
    )
  end

  def self.verify(token, domain:)
    data = VERIFIER.verify(token, purpose: :sso_login)
    return nil unless data[:domain] == domain

    data
  rescue ActiveSupport::MessageVerifier::InvalidSignature
    nil
  end
end
