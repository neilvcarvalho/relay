require "test_helper"

class NotificationsControllerTest < ActionDispatch::IntegrationTest
  include ActiveJob::TestHelper

  setup do
    @user = users(:one)
    sign_in_as @user
    @notification = notifications(:pending_banking)
  end

  # GET /notifications

  test "index lists pending notifications for the current user" do
    get notifications_path
    assert_response :ok
    assert_select "body", text: /Debit Alert/
  end

  test "index does not show completed notifications" do
    @notification.mark_completed!
    get notifications_path
    assert_response :ok
    assert_no_match(/Debit Alert/, response.body)
  end

  test "index does not show other users' notifications" do
    users(:two).notifications.create!(
      app_name: "other.app", title: "Other", text: "secret", raw_payload: "{}"
    )
    get notifications_path
    assert_no_match(/secret/, response.body)
  end

  test "index requires authentication" do
    sign_out
    get notifications_path
    assert_response :redirect
  end

  # GET /notifications/:id

  test "show renders the notification" do
    stub_ynab_plans
    get notification_path(@notification)
    assert_response :ok
  end

  test "show returns 404 for another user's notification" do
    other_notification = users(:two).notifications.create!(
      app_name: "other.app", title: "Other", text: "x", raw_payload: "{}"
    )
    get notification_path(other_notification)
    assert_response :not_found
  end

  # PATCH /notifications/:id — dispatch

  test "update dispatches notification to YNAB and redirects" do
    assert_enqueued_with(job: ProcessNotificationJob) do
      patch notification_path(@notification), params: {
        account_id: "account-uuid-5678",
        account_name: "Checking"
      }
    end
    assert_redirected_to notifications_path
  end

  test "update with discard marks notification as discarded" do
    patch notification_path(@notification), params: { discard: "1" }
    assert @notification.reload.discarded?
    assert_redirected_to notifications_path
  end

  test "update with save_as_rule creates a NotificationRule and YnabNotificationAction" do
    assert_difference "NotificationRule.count", 1 do
      assert_difference "YnabNotificationAction.count", 1 do
        patch notification_path(@notification), params: {
          account_id: "account-uuid-5678",
          account_name: "Checking",
          text_pattern: "Rs 500",
          description: "Debit alerts",
          save_as_rule: "1"
        }
      end
    end

    rule = @user.notification_rules.last
    assert_equal @notification.app_name, rule.app_name
    assert_equal "Rs 500", rule.text_pattern
    assert rule.string?
  end

  test "update requires authentication" do
    sign_out
    patch notification_path(@notification), params: { account_id: "x" }
    assert_response :redirect
  end

  private

  def stub_ynab_plans
    body = {
      data: {
        plans: [
          {
            id: "budget-uuid-1234",
            name: "Personal Budget",
            accounts: [
              { id: "account-uuid-5678", name: "Checking", on_budget: true, closed: false }
            ]
          }
        ]
      }
    }.to_json

    stub_request(:get, "https://api.ynab.com/v1/plans")
      .with(query: hash_including("include_accounts" => "true"))
      .to_return(status: 200, body: body, headers: { "Content-Type" => "application/json" })
  end
end
