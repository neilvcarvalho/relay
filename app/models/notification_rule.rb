class NotificationRule < ApplicationRecord
  belongs_to :user
  delegated_type :action, types: %w[YnabNotificationAction DiscardNotificationAction]

  enum :matcher_type, { string: 0, llm: 1 }

  validates :app_name, :matcher_type, presence: true
  validates :text_pattern,     presence: true, if: :string?
  validates :llm_instructions, presence: true, if: :llm?
  validates :position, uniqueness: { scope: [ :user_id, :app_name ] }

  scope :active, -> { where(active: true).order(:position) }

  def matches?(notification)
    return false unless notification.app_name.to_s.casecmp?(app_name)
    if string?
      notification.text.to_s.match?(Regexp.new(Regexp.escape(text_pattern), Regexp::IGNORECASE))
    elsif llm?
      LlmMatcherAgent.new.call(notification, llm_instructions)
    end
  end
end
