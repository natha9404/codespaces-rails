class NotificationRequest < ApplicationRecord
  # RECEIVED solo existe dentro de la transacción de admisión; el PolicyEngine
  # lo resuelve a REQUEST_ACCEPTED, COALESCED o SUPPRESSED antes del commit.
  STATUSES = %w[RECEIVED REQUEST_ACCEPTED COALESCED SUPPRESSED].freeze

  has_many :notification_deliveries, dependent: :destroy

  validates :idempotency_key, presence: true
  validates :status, inclusion: { in: STATUSES }
end
