require "test_helper"

class YnabNotificationActionTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper
  test "account_id is required" do
    action = YnabNotificationAction.new
    assert_not action.valid?
    assert_includes action.errors[:account_id], "can't be blank"
  end

  test "is valid with account_id" do
    action = YnabNotificationAction.new(account_id: "uuid-123")
    assert action.valid?
  end

  test "dispatch enqueues ProcessNotificationJob with the action's account_id" do
    action = ynab_notification_actions(:checking)
    notification = notifications(:pending_banking)

    assert_enqueued_with(job: ProcessNotificationJob, args: [ notification.id, { account_id: action.account_id } ]) do
      action.dispatch(notification)
    end
  end
end
