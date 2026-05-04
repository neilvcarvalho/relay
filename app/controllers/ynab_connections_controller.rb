class YnabConnectionsController < ApplicationController
  def show
    @connection = Current.user.ynab_connection
    redirect_to new_ynab_connection_path unless @connection
  end

  def new
    redirect_to ynab_connection_path if Current.user.ynab_connection
  end

  def create
    if params.dig(:ynab_connection, :plan_id).present?
      save_connection
    else
      validate_and_fetch_plans
    end
  end

  def destroy
    Current.user.ynab_connection&.destroy
    redirect_to new_ynab_connection_path, notice: "YNAB connection removed."
  end

  private

  def validate_and_fetch_plans
    token = params.dig(:ynab_connection, :access_token).to_s.strip
    api = YNAB::API.new(token)
    response = api.plans.get_plans(include_accounts: true)
    @plans = response.data.plans
    @access_token = token
    render :new
  rescue YNAB::ApiError => e
    flash.now[:alert] = "Could not connect to YNAB: #{e.detail || e.message}"
    render :new, status: :unprocessable_entity
  end

  def save_connection
    attrs = params.require(:ynab_connection)
                  .permit(:plan_id, :plan_name, :account_id, :account_name)
    connection = Current.user.ynab_connection || Current.user.build_ynab_connection
    connection.assign_attributes(attrs)
    token = params.dig(:ynab_connection, :access_token).to_s.strip
    connection.access_token = token if token.present?
    if connection.save
      redirect_to ynab_connection_path, notice: "YNAB connected successfully."
    else
      flash.now[:alert] = connection.errors.full_messages.to_sentence
      render :new, status: :unprocessable_entity
    end
  end
end
