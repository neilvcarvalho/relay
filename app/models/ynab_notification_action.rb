class YnabNotificationAction < ApplicationRecord
  has_one :notification_rule, as: :action

  validates :account_id, presence: true

  def dispatch(notification)
    ProcessNotificationJob.perform_later(notification.id, account_id: account_id)
  end
end
