# Aviso estático, prioridad estándar.
class PayslipAvailableNotification < AbstractNotification
  self.priority = :standard
  self.data_classification = :internal

  def self.title(_context) = "Tu liquidación de sueldo está disponible"
  def self.body(context)   = "Ya puedes revisar tu liquidación del período #{context[:period]} en Buk."
end
