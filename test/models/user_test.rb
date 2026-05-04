require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "downcases and strips email_address" do
    user = User.new(email_address: " DOWNCASED@EXAMPLE.COM ")
    assert_equal "downcased@example.com", user.email_address
  end

  test "generates a webhook_token before create" do
    user = User.create!(email_address: "new@example.com", password: "password")
    assert_not_empty user.webhook_token
    assert user.webhook_token.length >= 32
  end

  test "webhook_token is unique across users" do
    tokens = User.pluck(:webhook_token)
    assert_equal tokens.length, tokens.uniq.length
  end

  test "find_by_webhook_token returns the correct user" do
    assert_equal users(:one), User.find_by_webhook_token("token_for_user_one")
  end

  test "find_by_webhook_token returns nil for unknown token" do
    assert_nil User.find_by_webhook_token("bogus_token")
  end
end
