# Aviso estático, prioridad crítica: sus entregas van a la cola delivery_critical.
class ContractNoticeNotification < AbstractNotification
  self.priority = :critical
  self.data_classification = :confidential

  def self.title(_context) = "Tienes un aviso sobre tu contrato"
  def self.body(_context)  = "Ingresa a Buk para consultar el aviso."
end
