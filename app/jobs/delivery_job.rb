# Un job por entrega (canal). La cola se elige al encolar según la prioridad:
# delivery_critical o delivery_standard.
class DeliveryJob < ApplicationJob
  queue_as :delivery_standard

  def perform(delivery_id)
    # Prototipo: el envío real vía adaptador de canal está fuera del alcance
    # de este repositorio (ver documento técnico, sección 2.e).
  end
end
