require "test_helper"

class BankingNotificationAgentTest < ActiveSupport::TestCase
  setup do
    @agent = BankingNotificationAgent.new(llm_client: fake_llm(
      amount: -500000,
      payee_name: "Amazon",
      date: "2026-05-03",
      memo: "XX1234"
    ))
  end

  test "returns a Result with correct fields for a debit notification" do
    result = @agent.call("Rs 500.00 debited from XX1234 at AMAZON on 03-May-26")
    assert_equal(-500000, result.amount)
    assert_equal "Amazon", result.payee_name
    assert_equal "2026-05-03", result.date
    assert_equal "XX1234", result.memo
    assert_nil result.account_id
  end

  test "returns a Result with positive amount for a credit notification" do
    agent = BankingNotificationAgent.new(llm_client: fake_llm(
      amount: 200000,
      payee_name: "Salary",
      date: "2026-05-01",
      memo: ""
    ))
    result = agent.call("Rs 200.00 credited to your account")
    assert result.amount.positive?
  end

  test "raises AgentError when LLM does not call the extraction tool" do
    agent = BankingNotificationAgent.new(llm_client: no_tool_call_llm)
    assert_raises(BankingNotificationAgent::AgentError) do
      agent.call("some notification text")
    end
  end

  private

  def fake_llm(amount:, payee_name:, date:, memo: "")
    halt = RubyLLM::Tool::Halt.new(
      { "amount" => amount, "payee_name" => payee_name, "date" => date, "memo" => memo }
    )
    build_fake_llm_client(returning: halt)
  end

  def no_tool_call_llm
    build_fake_llm_client(returning: "I cannot parse this notification.")
  end

  def build_fake_llm_client(returning:)
    return_value = returning
    chat = Object.new
    chat.define_singleton_method(:with_instructions) { |*| chat }
    chat.define_singleton_method(:with_tool) { |*, **| chat }
    chat.define_singleton_method(:ask) { |*| return_value }

    client = Object.new
    client.define_singleton_method(:chat) { |**| chat }
    client
  end
end
