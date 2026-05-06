class NotificationsController < ApplicationController
  before_action :set_notification, only: [ :show, :update ]

  def index
    @notifications = Current.user.notifications.pending.order(created_at: :desc)
  end

  def show
    @plans = fetch_ynab_plans
  end

  def update
    if params[:discard] == "1"
      @notification.mark_discarded!
      redirect_to notifications_path, notice: "Notification discarded."
      return
    end

    if params[:save_as_rule] == "1"
      action = YnabNotificationAction.create!(
        account_id:   params[:account_id].to_s,
        account_name: params[:account_name].to_s
      )
      position = Current.user.notification_rules
                              .where(app_name: @notification.app_name)
                              .maximum(:position).to_i + 1
      Current.user.notification_rules.create!(
        app_name:     @notification.app_name,
        matcher_type: :string,
        text_pattern: params[:text_pattern].to_s,
        description:  params[:description].to_s,
        position:     position,
        action:       action
      )
    end

    ProcessNotificationJob.perform_later(@notification.id, account_id: params[:account_id].to_s)
    redirect_to notifications_path, notice: "Notification dispatched."
  end

  private

  def set_notification
    @notification = Current.user.notifications.find(params[:id])
  end

  def fetch_ynab_plans
    connection = Current.user.ynab_connection
    return [] unless connection

    api = YNAB::API.new(connection.access_token)
    response = api.plans.get_plans(include_accounts: true)
    response.data.plans.each do |plan|
      plan.accounts = (plan.accounts || []).reject(&:closed).select(&:on_budget)
    end
    response.data.plans
  rescue YNAB::ApiError
    []
  end
end
