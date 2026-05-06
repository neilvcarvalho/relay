require "test_helper"

class DiscardNotificationActionTest < ActiveSupport::TestCase
  test "dispatch marks the notification as discarded" do
    action = discard_notification_actions(:one)
    notification = notifications(:pending_banking)

    action.dispatch(notification)

    assert notification.discarded?
  end
end
