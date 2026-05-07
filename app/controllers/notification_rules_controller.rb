class NotificationRulesController < ApplicationController
  before_action :set_rule, only: [ :destroy, :move ]

  def index
    @rules = Current.user.notification_rules.order(:app_name, :position)
  end

  def new
    @rule = Current.user.notification_rules.build
    @plans = fetch_ynab_plans
  end

  def create
    action = build_action(params[:notification_rule][:action_type])

    unless action&.valid?
      @rule = Current.user.notification_rules.build
      @plans = fetch_ynab_plans
      render :new, status: :unprocessable_entity
      return
    end

    action.save!
    position = Current.user.notification_rules
                            .where(app_name: rule_params[:app_name])
                            .maximum(:position).to_i + 1
    @rule = Current.user.notification_rules.build(rule_params.merge(position: position, action: action))

    if @rule.save
      redirect_to notification_rules_path, notice: "Rule saved."
    else
      action.destroy
      @plans = fetch_ynab_plans
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    @rule.action.destroy if @rule.action.present?
    @rule.destroy
    redirect_to notification_rules_path, notice: "Rule removed."
  end

  def move
    sibling = Current.user.notification_rules
                          .where(app_name: @rule.app_name)
                          .where("position < ?", @rule.position)
                          .order(position: :desc)
                          .first

    if sibling
      old_rule_pos    = @rule.position
      old_sibling_pos = sibling.position

      # SQLite checks the unique constraint per row, so we use -1 as a safe
      # temporary position to avoid a conflict during the two-step swap.
      NotificationRule.transaction do
        @rule.update_column(:position, -1)
        sibling.update_column(:position, old_rule_pos)
        @rule.update_column(:position, old_sibling_pos)
      end
    end

    redirect_to notification_rules_path
  end

  private

  def set_rule
    @rule = Current.user.notification_rules.find(params[:id])
  end

  def rule_params
    params.require(:notification_rule).permit(:app_name, :matcher_type, :text_pattern, :llm_instructions, :description)
  end

  def build_action(action_type)
    case action_type
    when "ynab"
      YnabNotificationAction.new(
        account_id:   params.dig(:notification_rule, :account_id).to_s,
        account_name: params.dig(:notification_rule, :account_name).to_s
      )
    when "discard"
      DiscardNotificationAction.new
    end
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
