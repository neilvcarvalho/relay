require "net/http"
require "json"

class YnabClient
  BASE_URI = URI("https://api.ynab.com/v1")
  TIMEOUT = 10

  class Error < StandardError
    attr_reader :status

    def initialize(message, status: nil)
      super(message)
      @status = status
    end
  end

  def initialize(ynab_connection)
    @connection = ynab_connection
  end

  def create_transaction(account_id:, date:, amount:, payee_name: nil, memo: nil)
    body = {
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

    response = post("/budgets/#{@connection.budget_id}/transactions", body)
    response.dig("data", "transaction", "id") or
      raise Error.new("YNAB response missing transaction id", status: 200)
  end

  private

  def post(path, body)
    uri = URI(BASE_URI.to_s + path)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.open_timeout = TIMEOUT
    http.read_timeout = TIMEOUT

    request = Net::HTTP::Post.new(uri)
    request["Authorization"] = "Bearer #{@connection.access_token}"
    request["Content-Type"] = "application/json"
    request.body = JSON.generate(body)

    handle_response(http.request(request))
  end

  def handle_response(response)
    body = JSON.parse(response.body)
    case response.code.to_i
    when 200..299 then body
    when 401 then raise Error.new("YNAB: unauthorized — check access token", status: 401)
    when 400 then raise Error.new("YNAB: bad request — #{body.dig("error", "detail")}", status: 400)
    else raise Error.new("YNAB: unexpected status #{response.code}", status: response.code.to_i)
    end
  end
end
