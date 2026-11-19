class NotificationRequest < ApplicationRecord
  has_many :notification_deliveries, dependent: :destroy

  validates :idempotency_key, presence: true
  validates :status, inclusion: { in: %w[REQUEST_ACCEPTED SUPPRESSED] }
end