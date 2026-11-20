require "test_helper"

class DispatcherTest < ActiveJob::TestCase
  setup { Notifications::ChannelPreferences.reset! }

  test "deliver admite la solicitud, crea la entrega y encola un job por entrega" do
    result = nil
    assert_enqueued_jobs 1, only: DeliveryJob do
      result = PayslipAvailableNotification.deliver(
        "ana@example.com", context: { period: "2026-10" }, idempotency_key: "rrhh:liquidacion:1"
      )
    end

    request = result.request
    delivery = request.notification_deliveries.sole

    assert_not result.duplicate?
    assert_equal "REQUEST_ACCEPTED", request.status
    assert_equal "PENDING", delivery.status
    assert_equal "email", delivery.channel
    assert_enqueued_with(job: DeliveryJob, args: [ delivery.id ], queue: "delivery_standard")
  end

  test "una notificación crítica encola en delivery_critical" do
    result = ContractNoticeNotification.deliver(
      "ana@example.com", context: {}, idempotency_key: "rrhh:contrato:7"
    )

    delivery = result.request.notification_deliveries.sole
    assert_enqueued_with(job: DeliveryJob, args: [ delivery.id ], queue: "delivery_critical")
    assert_equal "critical", result.request.priority
  end

  test "la misma idempotency_key no duplica solicitud, entrega ni job" do
    args = { context: { period: "2026-10" }, idempotency_key: "rrhh:liquidacion:2" }

    first = PayslipAvailableNotification.deliver("ana@example.com", **args)
    second = nil

    assert_no_difference -> { NotificationRequest.count } do
      assert_no_difference -> { NotificationDelivery.count } do
        assert_no_enqueued_jobs only: DeliveryJob do
          second = PayslipAvailableNotification.deliver("ana@example.com", **args)
        end
      end
    end

    assert second.duplicate?
    assert_equal first.request.id, second.request.id
  end

  test "deliver exige idempotency_key" do
    assert_raises(ArgumentError) do
      PayslipAvailableNotification.deliver("ana@example.com", context: {})
    end

    assert_raises(ArgumentError) do
      PayslipAvailableNotification.deliver("ana@example.com", context: {}, idempotency_key: "")
    end
  end

  test "sin canal elegible la solicitud queda SUPPRESSED con razón y sin jobs" do
    Notifications::ChannelPreferences.disable!("ana@example.com", :email)
    result = nil

    assert_no_enqueued_jobs only: DeliveryJob do
      result = PayslipAvailableNotification.deliver(
        "ana@example.com", context: { period: "2026-10" }, idempotency_key: "rrhh:liquidacion:3"
      )
    end

    assert_equal "SUPPRESSED", result.request.status
    assert_equal "NO_ELIGIBLE_CHANNEL", result.request.decision_reason
    assert_empty result.request.notification_deliveries
  end

  test "el contexto y el email no quedan en claro en la base" do
    result = PayslipAvailableNotification.deliver(
      "ana@example.com", context: { period: "2026-10" }, idempotency_key: "rrhh:liquidacion:4"
    )
    request = result.request.reload
    delivery = request.notification_deliveries.sole

    assert_not_includes request.context_ciphertext, "ana@example.com"
    assert_not_includes request.context_ciphertext, "2026-10"
    assert_not_equal "ana@example.com", delivery.recipient_lookup_hash
    assert_equal Notifications::ContextVault.lookup_hash("ANA@example.com "), delivery.recipient_lookup_hash

    payload = Notifications::ContextVault.unseal(request.context_ciphertext)
    assert_equal "ana@example.com", payload[:recipient]
    assert_equal "2026-10", payload[:context][:period]
  end
end
