class BankingNotificationAgent
  Result = Data.define(:amount, :payee_name, :memo, :date, :account_id)

  AgentError = Class.new(StandardError)

  SYSTEM_PROMPT = <<~PROMPT.freeze
    You are a financial data extraction assistant. Given a mobile banking notification,
    extract the transaction details and call the extract_transaction tool.

    Rules:
    - amount: integer milliunits. Outflows (debits/purchases) are NEGATIVE. Inflows (credits/deposits) are POSITIVE.
      Multiply the currency amount by 1000. Example: Rs 500 spent = -500000. Rs 200 received = 200000.
    - payee_name: merchant or counterparty name. Clean up abbreviations and uppercase names.
    - date: ISO 8601 YYYY-MM-DD. If no date is mentioned, use today's date.
    - memo: include account last 4 digits or reference number if present. Leave blank otherwise.
  PROMPT

  class ExtractTransactionTool < RubyLLM::Tool
    description "Extract structured transaction data from a banking notification"

    param :amount, type: "integer",
          desc: "Amount in YNAB milliunits. Negative = outflow (debit). Positive = inflow (credit)."
    param :payee_name, type: "string",
          desc: "Merchant or counterparty name, cleaned up"
    param :date, type: "string",
          desc: "Transaction date as YYYY-MM-DD. Use today's date if not mentioned."
    param :memo, type: "string",
          desc: "Account last 4 digits or reference number, if present. Otherwise empty string.",
          required: false

    def execute(amount:, payee_name:, date:, memo: "")
      Tool::Halt.new({ "amount" => amount, "payee_name" => payee_name, "date" => date, "memo" => memo.to_s })
    end
  end

  def initialize(model: "claude-haiku-4-5-20251001", llm_client: RubyLLM)
    @model = model
    @llm_client = llm_client
  end

  def call(notification_text)
    result = @llm_client
      .chat(model: @model)
      .with_instructions(SYSTEM_PROMPT)
      .with_tool(ExtractTransactionTool, choice: :required)
      .ask(notification_text)

    unless result.is_a?(RubyLLM::Tool::Halt)
      raise AgentError, "LLM did not call the extract_transaction tool"
    end

    args = result.content
    Result.new(
      amount: Integer(args["amount"]),
      payee_name: args["payee_name"].to_s,
      memo: args["memo"].to_s,
      date: args["date"].to_s,
      account_id: nil
    )
  rescue TypeError, ArgumentError => e
    raise AgentError, "Invalid field in LLM response: #{e.message}"
  end
end
