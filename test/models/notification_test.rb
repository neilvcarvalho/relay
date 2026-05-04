require "test_helper"

class NotificationTest < ActiveSupport::TestCase
  test "belongs to a user" do
    assert_equal users(:one), notifications(:pending_banking).user
  end

  test "starts as pending" do
    assert notifications(:pending_banking).pending?
  end

  test "mark_processing! transitions to processing" do
    n = notifications(:pending_banking)
    n.mark_processing!
    assert n.processing?
  end

  test "mark_completed! transitions to completed" do
    n = notifications(:pending_banking)
    n.mark_completed!
    assert n.completed?
  end

  test "mark_failed! transitions to failed and stores message" do
    n = notifications(:pending_banking)
    n.mark_failed!("API timeout")
    assert n.failed?
    assert_equal "API timeout", n.error_message
  end

  test "raw_payload is required" do
    n = Notification.new(user: users(:one))
    assert_not n.valid?
    assert_includes n.errors[:raw_payload], "can't be blank"
  end
end
