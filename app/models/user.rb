class User < ApplicationRecord
  has_secure_password
  has_many :sessions, dependent: :destroy
  has_many :notifications, dependent: :destroy
  has_one :ynab_connection, dependent: :destroy
  has_many :notification_rules, dependent: :destroy

  normalizes :email_address, with: ->(e) { e.strip.downcase }

  before_create :generate_webhook_token

  def self.find_by_webhook_token(token)
    find_by(webhook_token: token)
  end

  private

  def generate_webhook_token
    self.webhook_token = SecureRandom.urlsafe_base64(32)
  end
end
