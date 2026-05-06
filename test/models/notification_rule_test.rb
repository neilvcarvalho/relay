require "test_helper"

class NotificationRuleTest < ActiveSupport::TestCase
  def notification(text:, app_name: "com.mybank")
    Notification.new(app_name: app_name, text: text, raw_payload: "{}")
  end

  # --- matcher_type enum ---

  test "string? returns true for string matcher" do
    assert notification_rules(:ted_income).string?
  end

  test "llm? returns true for llm matcher" do
    assert notification_rules(:llm_rule).llm?
  end

  # --- matches?: string matcher ---

  test "matches? returns true when app_name and text_pattern match (case-insensitive)" do
    rule = notification_rules(:ted_income)
    assert rule.matches?(notification(text: "TED recebido: R$ 1.500,00"))
  end

  test "matches? is case-insensitive on text" do
    rule = notification_rules(:ted_income)
    assert rule.matches?(notification(text: "ted recebido de joão"))
  end

  test "matches? returns false when app_name differs" do
    rule = notification_rules(:ted_income)
    assert_not rule.matches?(notification(text: "TED recebido: R$ 500,00", app_name: "other.app"))
  end

  test "matches? returns false when text does not contain pattern" do
    rule = notification_rules(:ted_income)
    assert_not rule.matches?(notification(text: "Compra aprovada em MERCADOLIVRE"))
  end

  # --- matches?: app_name required ---

  test "matches? compares app_name case-insensitively" do
    rule = notification_rules(:ted_income)
    assert rule.matches?(notification(text: "TED recebido", app_name: "COM.MYBANK"))
  end

  # --- active scope ---

  test "active scope returns only active rules ordered by position" do
    rules = users(:one).notification_rules.where(app_name: "com.mybank").active
    assert rules.all?(&:active?)
    assert_equal rules.map(&:position), rules.map(&:position).sort
  end

  # --- validations ---

  test "is valid with all required fields (string matcher)" do
    action = YnabNotificationAction.create!(account_id: "acc-1")
    rule = users(:one).notification_rules.build(
      app_name: "com.app",
      matcher_type: :string,
      text_pattern: "foo",
      position: 99,
      action: action
    )
    assert rule.valid?
  end

  test "is valid with llm matcher" do
    action = YnabNotificationAction.create!(account_id: "acc-1")
    rule = users(:one).notification_rules.build(
      app_name: "com.app",
      matcher_type: :llm,
      llm_instructions: "urgent tone",
      position: 100,
      action: action
    )
    assert rule.valid?
  end

  test "app_name is required" do
    action = YnabNotificationAction.create!(account_id: "acc-1")
    rule = users(:one).notification_rules.build(matcher_type: :string, text_pattern: "x", position: 99, action: action)
    assert_not rule.valid?
    assert_includes rule.errors[:app_name], "can't be blank"
  end

  test "text_pattern is required for string matcher" do
    action = YnabNotificationAction.create!(account_id: "acc-1")
    rule = users(:one).notification_rules.build(app_name: "com.app", matcher_type: :string, position: 99, action: action)
    assert_not rule.valid?
    assert_includes rule.errors[:text_pattern], "can't be blank"
  end

  test "llm_instructions is required for llm matcher" do
    action = YnabNotificationAction.create!(account_id: "acc-1")
    rule = users(:one).notification_rules.build(app_name: "com.app", matcher_type: :llm, position: 99, action: action)
    assert_not rule.valid?
    assert_includes rule.errors[:llm_instructions], "can't be blank"
  end

  test "position is unique per user and app_name" do
    action = YnabNotificationAction.create!(account_id: "acc-1")
    rule = users(:one).notification_rules.build(
      app_name: "com.mybank",
      matcher_type: :string,
      text_pattern: "x",
      position: 0,  # already taken by ted_income
      action: action
    )
    assert_not rule.valid?
    assert_includes rule.errors[:position], "has already been taken"
  end
end
