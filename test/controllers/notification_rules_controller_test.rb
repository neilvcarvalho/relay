require "test_helper"

class NotificationRulesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    sign_in_as @user
  end

  # GET /notification_rules

  test "index lists the user's rules" do
    get notification_rules_path
    assert_response :ok
    assert_select "body", text: /TED recebido/
  end

  test "index does not show other users' rules" do
    get notification_rules_path
    # users(:two) has no rules in fixtures
    assert_response :ok
  end

  test "index requires authentication" do
    sign_out
    get notification_rules_path
    assert_response :redirect
  end

  # GET /notification_rules/new

  test "new renders the form" do
    stub_ynab_plans
    get new_notification_rule_path
    assert_response :ok
  end

  # POST /notification_rules

  test "create with ynab action creates rule and action" do
    assert_difference "NotificationRule.count", 1 do
      assert_difference "YnabNotificationAction.count", 1 do
        post notification_rules_path, params: {
          notification_rule: {
            app_name: "com.newapp",
            matcher_type: "string",
            text_pattern: "New pattern",
            description: "A test rule",
            action_type: "ynab",
            account_id: "account-uuid-5678",
            account_name: "Checking"
          }
        }
      end
    end
    assert_redirected_to notification_rules_path
  end

  test "create with discard action creates rule and discard action" do
    assert_difference "NotificationRule.count", 1 do
      assert_difference "DiscardNotificationAction.count", 1 do
        post notification_rules_path, params: {
          notification_rule: {
            app_name: "com.spam",
            matcher_type: "string",
            text_pattern: "promo",
            description: "Discard promos",
            action_type: "discard"
          }
        }
      end
    end
    assert_redirected_to notification_rules_path
  end

  test "create with invalid params re-renders form" do
    stub_ynab_plans
    post notification_rules_path, params: {
      notification_rule: { app_name: "", matcher_type: "string" }
    }
    assert_response :unprocessable_entity
  end

  test "create requires authentication" do
    sign_out
    post notification_rules_path, params: { notification_rule: { app_name: "x" } }
    assert_response :redirect
  end

  # DELETE /notification_rules/:id

  test "destroy removes the rule" do
    rule = notification_rules(:ted_income)
    assert_difference "NotificationRule.count", -1 do
      delete notification_rule_path(rule)
    end
    assert_redirected_to notification_rules_path
  end

  test "destroy returns 404 for another user's rule" do
    rule = notification_rules(:ted_income)
    sign_out
    sign_in_as users(:two)
    delete notification_rule_path(rule)
    assert_response :not_found
  end

  # PATCH /notification_rules/:id/move

  test "move up swaps position with the rule above" do
    # ted_income is position 0, credit_card_purchase is position 1 (same app)
    ted   = notification_rules(:ted_income)
    cc    = notification_rules(:credit_card_purchase)

    patch move_notification_rule_path(cc)

    assert_equal 0, cc.reload.position
    assert_equal 1, ted.reload.position
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
