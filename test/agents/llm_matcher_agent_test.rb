require "test_helper"

class LlmMatcherAgentTest < ActiveSupport::TestCase
  def build_agent(matched:)
    halt = RubyLLM::Tool::Halt.new({ "matched" => matched })
    LlmMatcherAgent.new(llm_client: fake_llm(returning: halt))
  end

  def no_tool_call_agent
    LlmMatcherAgent.new(llm_client: fake_llm(returning: "I can't decide."))
  end

  def fake_llm(returning:)
    return_value = returning
    chat = Object.new
    chat.define_singleton_method(:with_instructions) { |*| chat }
    chat.define_singleton_method(:with_tool) { |*, **| chat }
    chat.define_singleton_method(:ask) { |*| return_value }

    client = Object.new
    client.define_singleton_method(:chat) { |**| chat }
    client
  end

  test "returns true when LLM says matched" do
    notification = notifications(:pending_banking)
    result = build_agent(matched: true).call(notification, "text mentions a debit")
    assert_equal true, result
  end

  test "returns false when LLM says not matched" do
    notification = notifications(:pending_banking)
    result = build_agent(matched: false).call(notification, "text is about food delivery")
    assert_equal false, result
  end

  test "raises AgentError when LLM does not call the tool" do
    notification = notifications(:pending_banking)
    assert_raises(LlmMatcherAgent::AgentError) do
      no_tool_call_agent.call(notification, "some instructions")
    end
  end
end
