class Webhooks::NotificationsController < ActionController::API
  before_action :authenticate_webhook!

  def create
    notification = current_user.notifications.create!(
      app_name: params[:app],
      title: params[:title],
      text: params[:text],
      raw_payload: request.raw_post
    )
    ProcessNotificationJob.perform_later(notification.id)
    head :accepted
  end

  private

  def authenticate_webhook!
    token = request.headers["Authorization"]&.delete_prefix("Bearer ")&.strip
    @current_user = User.find_by_webhook_token(token)
    head :unauthorized unless @current_user
  end

  def current_user
    @current_user
  end
end
