require "test_helper"

class SsoTokenTest < ActiveSupport::TestCase
  test "generate returns a token string" do
    token = SsoToken.generate(user_id: 1, domain: "example.com")
    assert_kind_of String, token
    assert token.present?
  end

  test "verify returns payload for valid token" do
    token = SsoToken.generate(user_id: 42, domain: "example.com", return_to: "/foo")
    data = SsoToken.verify(token, domain: "example.com")
    assert_equal 42, data[:user_id]
    assert_equal "example.com", data[:domain]
    assert_equal "/foo", data[:return_to]
  end

  test "verify returns nil for wrong domain" do
    token = SsoToken.generate(user_id: 1, domain: "example.com")
    assert_nil SsoToken.verify(token, domain: "evil.com")
  end

  test "verify returns nil for tampered token" do
    token = SsoToken.generate(user_id: 1, domain: "example.com")
    assert_nil SsoToken.verify("#{token}-tampered", domain: "example.com")
  end

  test "verify returns nil for expired token" do
    token = SsoToken.generate(user_id: 1, domain: "example.com")
    travel 6.minutes do
      assert_nil SsoToken.verify(token, domain: "example.com")
    end
  end

  test "default return_to is root" do
    token = SsoToken.generate(user_id: 1, domain: "example.com")
    data = SsoToken.verify(token, domain: "example.com")
    assert_equal "/", data[:return_to]
  end
end
