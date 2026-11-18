class Tenant < ApplicationRecord
  has_many :notification_requests
end