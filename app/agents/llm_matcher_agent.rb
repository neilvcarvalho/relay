class LlmMatcherAgent
  AgentError = Class.new(StandardError)

  class MatchTool < RubyLLM::Tool
    description "Report whether the notification matches the given criteria"

    param :matched, type: "boolean",
          desc: "true if the notification matches the criteria, false otherwise"

    def execute(matched:)
      Tool::Halt.new({ "matched" => matched })
    end
  end

  def initialize(model: "claude-haiku-4-5-20251001", llm_client: RubyLLM)
    @model = model
    @llm_client = llm_client
  end

  def call(notification, instructions)
    prompt = <<~PROMPT
      Notification app: #{notification.app_name}
      Notification title: #{notification.title}
      Notification text: #{notification.text}

      Does this notification match the following criteria?
      #{instructions}

      Call the match tool with your answer.
    PROMPT

    result = @llm_client
      .chat(model: @model)
      .with_instructions("You are a notification classifier. Evaluate whether a notification matches given criteria and call the match tool.")
      .with_tool(MatchTool, choice: :required)
      .ask(prompt)

    unless result.is_a?(RubyLLM::Tool::Halt)
      raise AgentError, "LLM did not call the match tool"
    end

    result.content["matched"] == true
  end
end
