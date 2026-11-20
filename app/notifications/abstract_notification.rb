# API declarativa: cada tipo de aviso declara su definición y no conoce
# canales, colas ni proveedores. Es el equivalente a un modelo base de Django.
class AbstractNotification
  class_attribute :priority, default: :standard
  class_attribute :data_classification, default: :internal
  class_attribute :channels, default: [ :email ]

  class << self
    # idempotency_key es obligatoria: sin ella Ruby lanza ArgumentError.
    def deliver(recipient, context:, idempotency_key:)
      Notifications::Dispatcher.call(
        self, recipient:, context:, idempotency_key:
      )
    end

    def title(_context) = raise(NotImplementedError, "#{name} debe definir title(context)")
    def body(_context)  = raise(NotImplementedError, "#{name} debe definir body(context)")
  end
end
