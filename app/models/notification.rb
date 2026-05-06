class Notification < ApplicationRecord
  belongs_to :user

  enum :status, { pending: 0, processing: 1, completed: 2, failed: 3, discarded: 4 }

  validates :raw_payload, presence: true

  def mark_processing!
    update!(status: :processing)
  end

  def mark_completed!
    update!(status: :completed)
  end

  def mark_failed!(message)
    update!(status: :failed, error_message: message)
  end

  def mark_discarded!
    update!(status: :discarded)
  end
end
