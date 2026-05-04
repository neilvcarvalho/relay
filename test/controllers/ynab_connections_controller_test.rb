require "test_helper"

class YnabConnectionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    sign_in_as @user
  end

  # GET /ynab_connection/new

  test "new renders token form when no connection" do
    @user.ynab_connection.destroy
    get new_ynab_connection_path
    assert_response :ok
  end

  test "new redirects to show when connection already exists" do
    get new_ynab_connection_path
    assert_redirected_to ynab_connection_path
  end

  # GET /ynab_connection

  test "show renders connection when it exists" do
    get ynab_connection_path
    assert_response :ok
  end

  test "show redirects to new when no connection" do
    @user.ynab_connection.destroy
    get ynab_connection_path
    assert_redirected_to new_ynab_connection_path
  end

  # POST /ynab_connection — step 1: validate token

  test "create step 1 validates token and renders plan selection on success" do
    @user.ynab_connection.destroy
    stub_ynab_plans

    post ynab_connection_path, params: { ynab_connection: { access_token: "valid_token" } }

    assert_response :ok
    assert_select "select[id='plan-select']"
    assert_select "select[id='account-select']"
  end

  test "create step 1 re-renders form with error when token is invalid" do
    @user.ynab_connection.destroy
    stub_request(:get, "https://api.ynab.com/v1/plans").with(query: hash_including("include_accounts" => "true"))
      .to_return(status: 401,
                 body: { error: { id: "401", name: "unauthorized", detail: "Bad token" } }.to_json,
                 headers: { "Content-Type" => "application/json" })

    post ynab_connection_path, params: { ynab_connection: { access_token: "bad_token" } }

    assert_response :unprocessable_entity
    assert_select "form"
  end

  # POST /ynab_connection — step 2: save connection

  test "create step 2 saves connection and redirects to show" do
    @user.ynab_connection.destroy
    assert_difference "YnabConnection.count", 1 do
      post ynab_connection_path, params: {
        ynab_connection: {
          access_token: "valid_token",
          plan_id: "plan-uuid",
          plan_name: "Personal Budget",
          account_id: "account-uuid",
          account_name: "Checking"
        }
      }
    end
    assert_redirected_to ynab_connection_path
  end

  test "create step 2 updates existing connection" do
    assert_no_difference "YnabConnection.count" do
      post ynab_connection_path, params: {
        ynab_connection: {
          access_token: "new_token",
          plan_id: "new-plan-uuid",
          plan_name: "New Plan",
          account_id: "new-account-uuid",
          account_name: "Savings"
        }
      }
    end
    assert_equal "new-plan-uuid", @user.ynab_connection.reload.plan_id
  end

  # DELETE /ynab_connection

  test "destroy removes the connection and redirects to new" do
    assert_difference "YnabConnection.count", -1 do
      delete ynab_connection_path
    end
    assert_redirected_to new_ynab_connection_path
  end

  private

  def stub_ynab_plans
    body = {
      data: {
        plans: [
          {
            id: "plan-uuid",
            name: "Personal Budget",
            accounts: [
              { id: "account-uuid", name: "Checking", on_budget: true, closed: false }
            ]
          }
        ]
      }
    }.to_json

    stub_request(:get, "https://api.ynab.com/v1/plans").with(query: hash_including("include_accounts" => "true"))
      .to_return(status: 200, body: body, headers: { "Content-Type" => "application/json" })
  end
end
