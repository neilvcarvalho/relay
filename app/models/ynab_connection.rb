class YnabConnection < ApplicationRecord
  belongs_to :user

  encrypts :access_token
  encrypts :refresh_token

  validates :access_token, :plan_id, :account_id, presence: true

  def token_expired?
    expires_at.present? && expires_at <= Time.current
  end
end
