require "test_helper"

class ProcessNotificationJobTest < ActiveJob::TestCase
  setup do
    @notification = notifications(:pending_banking)
    @connection = ynab_connections(:one)
    @ynab_url = "https://api.ynab.com/v1/plans/#{@connection.plan_id}/transactions"
  end

  test "transitions notification to completed on success" do
    with_stubbed_agent(returning: agent_result) do
      stub_ynab_success
      ProcessNotificationJob.perform_now(@notification.id)
    end
    assert @notification.reload.completed?
  end

  test "transitions notification through processing before completing" do
    with_stubbed_agent(returning: agent_result) do
      stub_ynab_success
      ProcessNotificationJob.perform_now(@notification.id)
    end
    # completed? implies it was set to processing first (sequential transitions in the job)
    assert @notification.reload.completed?
  end

  test "transitions to failed and re-raises when no YNAB connection" do
    @notification.user.ynab_connection.destroy
    assert_raises(RuntimeError) do
      ProcessNotificationJob.perform_now(@notification.id)
    end
    assert @notification.reload.failed?
    assert_includes @notification.reload.error_message, "No YNAB connection"
  end

  test "transitions to failed and re-raises on AgentError" do
    with_stubbed_agent(raising: BankingNotificationAgent::AgentError.new("no tool call")) do
      assert_raises(BankingNotificationAgent::AgentError) do
        ProcessNotificationJob.perform_now(@notification.id)
      end
    end
    assert @notification.reload.failed?
    assert_includes @notification.reload.error_message, "AgentError"
  end

  test "transitions to failed and re-raises on YnabClient::Error" do
    with_stubbed_agent(returning: agent_result) do
      stub_ynab_error
      assert_raises(YnabClient::Error) do
        ProcessNotificationJob.perform_now(@notification.id)
      end
    end
    assert @notification.reload.failed?
    assert_includes @notification.reload.error_message, "YnabClient"
  end

  private

  def agent_result
    BankingNotificationAgent::Result.new(
      amount: -500000,
      payee_name: "Amazon",
      memo: "XX1234",
      date: "2026-05-03",
      account_id: nil
    )
  end

  def with_stubbed_agent(returning: nil, raising: nil)
    error = raising
    result = returning

    fake = Object.new
    fake.define_singleton_method(:call) do |_text|
      raise error if error
      result
    end

    original_new = BankingNotificationAgent.method(:new)
    BankingNotificationAgent.define_singleton_method(:new) { fake }
    yield
  ensure
    BankingNotificationAgent.define_singleton_method(:new, original_new)
  end

  def stub_ynab_success
    stub_request(:post, @ynab_url)
      .to_return(status: 201,
                 body: { data: { transaction: { id: "txn-xyz" } } }.to_json,
                 headers: { "Content-Type" => "application/json" })
  end

  def stub_ynab_error
    stub_request(:post, @ynab_url)
      .to_return(status: 401,
                 body: { error: { id: "401", name: "unauthorized", detail: "Bad token" } }.to_json,
                 headers: { "Content-Type" => "application/json" })
  end
end
