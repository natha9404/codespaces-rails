# Central de notificaciones: prototipo

Prototipo de la propuesta técnica *Central de notificaciones* (Buk, Core AI).
Implementa un **flujo mínimo** que corre y tiene pruebas. El resto del diseño
(IA, COALESCE, frecuencia, auditoría) vive en el documento técnico, no aquí.

## Qué está implementado

```
Notification.deliver(recipient, context:, idempotency_key:)
  → Notifications::Dispatcher   transacción corta: solicitud + entregas + jobs
  → Notifications::PolicyEngine DELIVER o SUPPRESS (sin canal elegible)
  → DeliveryJob                 un job por entrega; cola crítica o estándar
  → SendgridEmailAdapter        cliente SendGrid simulado (sin red); 202 = ACCEPTED
```

- **Idempotencia:** `UNIQUE(idempotency_key)`; una repetición devuelve la solicitud original.
- **Atomicidad:** Solid Queue comparte el pool de la aplicación; ver `test/services/notification_enqueue_atomicity_test.rb`.
- **Entregas inciertas:** un timeout deja la entrega en `UNKNOWN`; no se reenvía a ciegas.
- **Datos personales:** contexto cifrado y destinatario como HMAC en la base.
- **Pools por etapa:** `config/queue.yml` define workers para `delivery_critical`, `delivery_standard` y `ai_generation`.

## Qué es solo diseño (no está en el código)

Generación con IA y guardrails, Frequency Capping, COALESCE, webhook de SendGrid,
reconciliación y la interfaz de auditoría.

## Ejecutar

PostgreSQL debe escuchar en `localhost:5433` (ver `config/database.yml`).

```bash
bin/rails db:prepare
bin/rails test
```
