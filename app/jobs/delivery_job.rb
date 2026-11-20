# Un job por entrega (canal). La cola se elige al encolar según la prioridad:
# delivery_critical o delivery_standard.
class DeliveryJob < ApplicationJob
  queue_as :delivery_standard

  CLAIMABLE = %w[PENDING RETRY_WAIT].freeze

  def perform(delivery_id)
    delivery = NotificationDelivery.find(delivery_id)
    return unless claim!(delivery)

    request = delivery.notification_request
    notification_class = notification_class_for(request)
    payload = Notifications::ContextVault.unseal(request.context_ciphertext)
    context = payload[:context]

    begin
      result = SendgridEmailAdapter.new.deliver!(
        delivery_id: delivery.id,
        recipient: payload[:recipient],
        title: notification_class.title(context),
        body: notification_class.body(context)
      )
      delivery.update!(status: "ACCEPTED", provider_message_id: result[:provider_message_id])
    rescue ProviderRejected
      delivery.update!(status: "FAILED", decision_reason: "PROVIDER_REJECTED")
    rescue Timeout::Error
      # No sabemos si el proveedor recibió el mensaje: no se reenvía a ciegas.
      delivery.update!(status: "UNKNOWN", decision_reason: "PROVIDER_TIMEOUT")
    end
  end

  private

  # Solo un worker pasa de PENDING/RETRY_WAIT a SUBMITTING. Una re-ejecución del
  # mismo job (at-least-once) encuentra otro estado y no vuelve a llamar al proveedor.
  def claim!(delivery)
    delivery.with_lock do
      next false unless CLAIMABLE.include?(delivery.status)

      delivery.update!(status: "SUBMITTING")
      true
    end
  end

  def notification_class_for(request)
    klass = request.notification_type.to_s.safe_constantize
    raise ArgumentError, "Tipo de notificación inválido: #{request.notification_type}" unless klass.is_a?(Class) && klass < AbstractNotification

    klass
  end
end
