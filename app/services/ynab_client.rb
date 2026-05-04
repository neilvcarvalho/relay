class YnabClient
  class Error < StandardError
    attr_reader :status

    def initialize(message, status: nil)
      super(message)
      @status = status
    end
  end

  def initialize(ynab_connection)
    @api = YNAB::API.new(ynab_connection.access_token)
    @connection = ynab_connection
  end

  def create_transaction(account_id:, date:, amount:, payee_name: nil, memo: nil)
    response = @api.transactions.create_transaction(
      @connection.plan_id,
      {
        transaction: {
          account_id: account_id,
          date: date,
          amount: amount,
          payee_name: payee_name,
          memo: memo,
          cleared: "cleared",
          approved: true
        }
      }
    )
    response.data.transaction.id
  rescue YNAB::ApiError => e
    raise Error.new(e.detail || e.message, status: e.code)
  end
end
