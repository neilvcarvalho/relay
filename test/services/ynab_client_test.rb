require "test_helper"

class YnabClientTest < ActiveSupport::TestCase
  setup do
    @connection = ynab_connections(:one)
    @client = YnabClient.new(@connection)
    @ynab_url = "https://api.ynab.com/v1/plans/#{@connection.plan_id}/transactions"
    @valid_params = {
      account_id: @connection.account_id,
      date: "2026-05-03",
      amount: -12500,
      payee_name: "Amazon",
      memo: "XX1234"
    }
  end

  test "create_transaction posts to the correct YNAB endpoint" do
    stub_request(:post, @ynab_url)
      .to_return(status: 201, body: successful_response("txn-abc-123"), headers: json_headers)

    id = @client.create_transaction(**@valid_params)
    assert_equal "txn-abc-123", id
  end

  test "create_transaction sends Bearer token in Authorization header" do
    stub_request(:post, @ynab_url)
      .with(headers: { "Authorization" => "Bearer fake_ynab_pat_for_user_one" })
      .to_return(status: 201, body: successful_response("txn-abc-123"), headers: json_headers)

    @client.create_transaction(**@valid_params)
    assert_requested :post, @ynab_url
  end

  test "create_transaction sends correct transaction body" do
    stub_request(:post, @ynab_url)
      .with(body: hash_including(
        "transaction" => hash_including(
          "amount" => -12500,
          "payee_name" => "Amazon",
          "cleared" => "cleared",
          "approved" => true
        )
      ))
      .to_return(status: 201, body: successful_response("txn-abc-123"), headers: json_headers)

    @client.create_transaction(**@valid_params)
    assert_requested :post, @ynab_url
  end

  test "raises YnabClient::Error on 401" do
    stub_request(:post, @ynab_url)
      .to_return(status: 401, body: error_response("401", "unauthorized"), headers: json_headers)

    error = assert_raises(YnabClient::Error) { @client.create_transaction(**@valid_params) }
    assert_equal 401, error.status
  end

  test "raises YnabClient::Error on 400 with detail message" do
    stub_request(:post, @ynab_url)
      .to_return(status: 400, body: error_response("400", "bad_request", "Invalid account_id"), headers: json_headers)

    error = assert_raises(YnabClient::Error) { @client.create_transaction(**@valid_params) }
    assert_equal 400, error.status
    assert_includes error.message, "Invalid account_id"
  end

  test "raises YnabClient::Error on unexpected status" do
    stub_request(:post, @ynab_url).to_return(status: 500, body: "{}", headers: json_headers)

    error = assert_raises(YnabClient::Error) { @client.create_transaction(**@valid_params) }
    assert_equal 500, error.status
  end

  private

  def successful_response(transaction_id)
    { data: { transaction: { id: transaction_id } } }.to_json
  end

  def error_response(id, name, detail = "Something went wrong")
    { error: { id: id, name: name, detail: detail } }.to_json
  end

  def json_headers
    { "Content-Type" => "application/json" }
  end
end
