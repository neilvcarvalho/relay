class MatchAndDispatchNotificationJob < ApplicationJob
  queue_as :default

  def perform(notification_id)
    notification = Notification.find(notification_id)
    rule = notification.user.notification_rules.active.find { |r| r.matches?(notification) }
    rule&.action&.dispatch(notification)
  end
end
