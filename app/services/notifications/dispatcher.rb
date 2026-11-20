module Notifications
  # Admisión: una transacción corta guarda la solicitud, sus entregas y los jobs
  # en la misma base (Solid Queue comparte el pool de la aplicación). Ninguna
  # llamada externa ocurre aquí.
  class Dispatcher
    Result = Struct.new(:request, :duplicate, keyword_init: true) do
      def duplicate? = duplicate
    end

    def self.call(...) = new(...).call

    def initialize(notification_class, recipient:, context:, idempotency_key:)
      @notification_class = notification_class
      @recipient = recipient
      @context = context
      @idempotency_key = idempotency_key.to_s
    end

    def call
      raise ArgumentError, "idempotency_key es obligatoria" if @idempotency_key.blank?

      existing = NotificationRequest.find_by(idempotency_key: @idempotency_key)
      return Result.new(request: existing, duplicate: true) if existing

      Result.new(request: admit!, duplicate: false)
    rescue ActiveRecord::RecordNotUnique
      # Carrera entre dos solicitudes con la misma clave: gana la primera.
      Result.new(request: NotificationRequest.find_by!(idempotency_key: @idempotency_key), duplicate: true)
    end

    private

    # requires_new: true usa un SAVEPOINT, así RecordNotUnique deja la conexión
    # utilizable también dentro de transacciones externas (por ejemplo, en tests).
    def admit!
      NotificationRequest.transaction(requires_new: true) do
        request = NotificationRequest.create!(
          idempotency_key: @idempotency_key,
          notification_type: @notification_class.name,
          priority: @notification_class.priority.to_s,
          context_ciphertext: ContextVault.seal(recipient: @recipient, context: @context),
          status: "RECEIVED"
        )

        decision = PolicyEngine.evaluate(@notification_class, recipient: @recipient)

        case decision.action
        when :deliver
          deliveries = decision.channels.map do |channel|
            request.notification_deliveries.create!(
              channel: channel.to_s,
              status: "PENDING",
              recipient_lookup_hash: ContextVault.lookup_hash(@recipient)
            )
          end
          request.update!(status: "REQUEST_ACCEPTED", decision_reason: decision.reason)
          deliveries.each { |delivery| DeliveryJob.set(queue: queue_name).perform_later(delivery.id) }
        when :suppress
          request.update!(status: "SUPPRESSED", decision_reason: decision.reason)
        else
          raise ArgumentError, "Unsupported notification policy: #{decision.action}"
        end

        request
      end
    end

    def queue_name
      @notification_class.priority == :critical ? :delivery_critical : :delivery_standard
    end
  end
end
