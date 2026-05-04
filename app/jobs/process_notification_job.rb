class ProcessNotificationJob < ApplicationJob
  queue_as :default

  def perform(notification_id)
    # Implemented in slice 7
  end
end
