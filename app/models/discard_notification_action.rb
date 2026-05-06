class DiscardNotificationAction < ApplicationRecord
  has_one :notification_rule, as: :action

  def dispatch(notification)
    notification.mark_discarded!
  end
end
