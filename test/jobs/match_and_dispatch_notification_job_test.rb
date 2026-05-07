require "test_helper"

class MatchAndDispatchNotificationJobTest < ActiveJob::TestCase
  setup do
    @notification = notifications(:pending_banking)
  end

  test "enqueues ProcessNotificationJob when a string rule matches" do
    rule = notification_rules(:ted_income)
    @notification.update!(text: "TED recebido: R$ 500,00", app_name: rule.app_name)

    assert_enqueued_with(job: ProcessNotificationJob) do
      MatchAndDispatchNotificationJob.perform_now(@notification.id)
    end
  end

  test "passes the rule's account_id to ProcessNotificationJob" do
    rule = notification_rules(:ted_income)
    @notification.update!(text: "TED recebido: R$ 500,00", app_name: rule.app_name)

    MatchAndDispatchNotificationJob.perform_now(@notification.id)

    job = enqueued_jobs.first
    assert_equal rule.ynab_notification_action.account_id, job.dig(:args, 1, "account_id")
  end

  test "discards notification when a discard rule matches" do
    @notification.update!(text: "promo: get 50% off!", app_name: "com.spam")

    MatchAndDispatchNotificationJob.perform_now(@notification.id)

    assert @notification.reload.discarded?
  end

  test "does not enqueue any job when no rule matches" do
    @notification.update!(text: "something unrecognised", app_name: "com.unknown")

    assert_no_enqueued_jobs do
      MatchAndDispatchNotificationJob.perform_now(@notification.id)
    end
  end

  test "notification stays pending when no rule matches" do
    @notification.update!(text: "something unrecognised", app_name: "com.unknown")
    MatchAndDispatchNotificationJob.perform_now(@notification.id)
    assert @notification.reload.pending?
  end

  test "llm rule: dispatches when LlmMatcherAgent returns true" do
    rule = notification_rules(:llm_rule)
    @notification.update!(text: "URGENT: something happened", app_name: rule.app_name)

    stub_llm_matcher(returning: true) do
      assert_enqueued_with(job: ProcessNotificationJob) do
        MatchAndDispatchNotificationJob.perform_now(@notification.id)
      end
    end
  end

  test "llm rule: does not dispatch when LlmMatcherAgent returns false" do
    rule = notification_rules(:llm_rule)
    # text matches string rules first — use app_name with only an llm rule to isolate
    @notification.update!(text: "routine update", app_name: rule.app_name)

    # disable string rules for this test by making the text not match them
    stub_llm_matcher(returning: false) do
      # only the llm_rule is relevant for app_name=com.mybank with no string match
      # But string rules for com.mybank also exist; we need a text that matches none of them
      assert_enqueued_jobs 0 do
        MatchAndDispatchNotificationJob.perform_now(@notification.id)
      end
    end
  end

  private

  def stub_llm_matcher(returning:)
    result = returning
    original_new = LlmMatcherAgent.method(:new)
    fake = Object.new
    fake.define_singleton_method(:call) { |*, **| result }
    LlmMatcherAgent.define_singleton_method(:new) { fake }
    yield
  ensure
    LlmMatcherAgent.define_singleton_method(:new, original_new)
  end
end
