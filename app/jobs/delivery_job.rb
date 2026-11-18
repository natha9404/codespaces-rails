class DeliveryJob < ApplicationJob
  queue_as :delivery_critical

  def perform(request_id)
    # El envío real se implementa en la siguiente iteración.
  end
end