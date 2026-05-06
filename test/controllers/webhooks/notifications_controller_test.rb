require "test_helper"

class Webhooks::NotificationsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    @token = @user.webhook_token
    @payload = { app: "com.mybank", title: "Debit Alert", text: "Rs 500 at Amazon" }.to_json
    @headers = { "Authorization" => "Bearer #{@token}", "Content-Type" => "application/json" }
  end

  test "returns 202 with valid token" do
    post webhooks_notifications_path, params: @payload, headers: @headers
    assert_response :accepted
  end

  test "enqueues MatchAndDispatchNotificationJob with valid token" do
    assert_enqueued_with(job: MatchAndDispatchNotificationJob) do
      post webhooks_notifications_path, params: @payload, headers: @headers
    end
  end

  test "creates a Notification for the correct user" do
    assert_difference "@user.notifications.count", 1 do
      post webhooks_notifications_path, params: @payload, headers: @headers
    end
    n = @user.notifications.last
    assert_equal "com.mybank", n.app_name
    assert_equal "Debit Alert", n.title
    assert_equal "Rs 500 at Amazon", n.text
    assert n.pending?
  end

  test "returns 401 when Authorization header is missing" do
    post webhooks_notifications_path, params: @payload,
         headers: { "Content-Type" => "application/json" }
    assert_response :unauthorized
  end

  test "returns 401 when token is wrong" do
    post webhooks_notifications_path, params: @payload,
         headers: { "Authorization" => "Bearer wrong_token", "Content-Type" => "application/json" }
    assert_response :unauthorized
  end

  test "does not enqueue job on auth failure" do
    assert_no_enqueued_jobs do
      post webhooks_notifications_path, params: @payload,
           headers: { "Authorization" => "Bearer wrong_token", "Content-Type" => "application/json" }
    end
  end

  test "does not create a notification on auth failure" do
    assert_no_difference "Notification.count" do
      post webhooks_notifications_path, params: @payload,
           headers: { "Authorization" => "Bearer wrong_token", "Content-Type" => "application/json" }
    end
  end
end
