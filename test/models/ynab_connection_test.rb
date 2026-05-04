require "test_helper"

class YnabConnectionTest < ActiveSupport::TestCase
  test "belongs to a user" do
    assert_equal users(:one), ynab_connections(:one).user
  end

  test "access_token is required" do
    conn = YnabConnection.new(user: users(:two), budget_id: "b", account_id: "a")
    assert_not conn.valid?
    assert_includes conn.errors[:access_token], "can't be blank"
  end

  test "budget_id is required" do
    conn = YnabConnection.new(user: users(:two), access_token: "tok", account_id: "a")
    assert_not conn.valid?
    assert_includes conn.errors[:budget_id], "can't be blank"
  end

  test "account_id is required" do
    conn = YnabConnection.new(user: users(:two), access_token: "tok", budget_id: "b")
    assert_not conn.valid?
    assert_includes conn.errors[:account_id], "can't be blank"
  end

  test "access_token is encrypted at rest" do
    conn = YnabConnection.create!(
      user: users(:two),
      access_token: "supersecret_pat",
      budget_id: "b-1",
      account_id: "a-1"
    )
    raw = ActiveRecord::Base.connection.select_value(
      "SELECT access_token FROM ynab_connections WHERE id = #{conn.id}"
    )
    assert_not_equal "supersecret_pat", raw
  end

  test "token_expired? returns false when expires_at is nil" do
    assert_not ynab_connections(:one).token_expired?
  end

  test "token_expired? returns true when expires_at is in the past" do
    conn = ynab_connections(:one)
    conn.expires_at = 1.hour.ago
    assert conn.token_expired?
  end
end
