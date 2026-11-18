class NotificationDelivery < ApplicationRecord
  STATUSES = %w[PENDING SCHEDULED PROCESSING SUBMITTING ACCEPTED DELIVERED
                RETRY_WAIT UNKNOWN FAILED SUPPRESSED].freeze

  belongs_to :notification_request
  validates :status, inclusion: { in: STATUSES }
end