require "test_helper"

class NotificationEnqueueAtomicityTest < ActiveSupport::TestCase
  class ForcedFailureAfterEnqueue < StandardError; end

  setup do
    @previous_adapter = ActiveJob::Base.queue_adapter
    ActiveJob::Base.queue_adapter = :solid_queue
  end

  teardown do
    ActiveJob::Base.queue_adapter = @previous_adapter
  end

  test "Solid Queue usa el mismo pool de conexiones que la aplicación" do
    assert_same ActiveRecord::Base.connection_pool,
                SolidQueue::Record.connection_pool,
                "Solid Queue debe compartir el pool para que el job entre en la misma transacción"
  end

  test "las tablas de Solid Queue existen en la base primaria" do
    assert SolidQueue::Job.table_exists?, "falta solid_queue_jobs"
  end

  test "un error después de encolar no deja solicitud, entregas ni job" do
    jobs_inside_transaction = nil

    assert_no_difference -> { NotificationRequest.count } do
      assert_no_difference -> { NotificationDelivery.count } do
        assert_no_difference -> { SolidQueue::Job.count } do
          assert_raises(ForcedFailureAfterEnqueue) do
            # requires_new: true crea un SAVEPOINT; sin él el rollback no ocurre
            # dentro de los tests transaccionales de Rails.
            NotificationRequest.transaction(requires_new: true) do
              request = NotificationRequest.create!(
                idempotency_key: "test-atomicity-1",
                status: "REQUEST_ACCEPTED"
              )
              NotificationDelivery.create!(
                notification_request: request,
                channel: "email",
                status: "PENDING"
              )
              DeliveryJob.set(queue: :delivery_critical).perform_later(request.id)

              jobs_inside_transaction = SolidQueue::Job.count
              raise ForcedFailureAfterEnqueue, "fallo forzado tras encolar"
            end
          end
        end
      end
    end

    assert_operator jobs_inside_transaction, :>, 0,
                    "el job debía existir dentro de la transacción antes del fallo"
  end
end