require "test_helper"

class DeliveryJobTest < ActiveJob::TestCase
  setup do
    Notifications::ChannelPreferences.reset!
    SendgridClient.reset!
  end

  teardown { SendgridClient.reset! }

  def build_delivery(key:, context: { period: "2026-10" })
    result = PayslipAvailableNotification.deliver("ana@example.com", context:, idempotency_key: key)
    result.request.notification_deliveries.sole
  end

  test "una respuesta 202 deja la entrega en ACCEPTED con el id del proveedor" do
    delivery = build_delivery(key: "job:1")

    DeliveryJob.perform_now(delivery.id)

    delivery.reload
    assert_equal "ACCEPTED", delivery.status
    assert_match(/\Asim-/, delivery.provider_message_id)
  end

  test "un rechazo del proveedor deja la entrega en FAILED" do
    SendgridClient.transport = ->(_path, _payload) { SendgridClient::Response.new(status: 400, headers: {}) }
    delivery = build_delivery(key: "job:2")

    DeliveryJob.perform_now(delivery.id)

    assert_equal "FAILED", delivery.reload.status
    assert_equal "PROVIDER_REJECTED", delivery.decision_reason
  end

  test "un timeout deja la entrega en UNKNOWN y no se reenvía a ciegas" do
    SendgridClient.transport = ->(_path, _payload) { raise Timeout::Error }
    delivery = build_delivery(key: "job:3")

    DeliveryJob.perform_now(delivery.id)

    assert_equal "UNKNOWN", delivery.reload.status
    assert_equal "PROVIDER_TIMEOUT", delivery.decision_reason
  end

  test "re-ejecutar el job sobre una entrega ya enviada no llama de nuevo al proveedor" do
    calls = 0
    SendgridClient.transport = lambda do |_path, _payload|
      calls += 1
      SendgridClient::Response.new(status: 202, headers: { "x-message-id" => "m-1" })
    end
    delivery = build_delivery(key: "job:4")

    DeliveryJob.perform_now(delivery.id)
    DeliveryJob.perform_now(delivery.id)

    assert_equal 1, calls
    assert_equal "ACCEPTED", delivery.reload.status
  end

  test "el cuerpo se escapa como HTML antes de enviarse" do
    sent = nil
    SendgridClient.transport = lambda do |_path, payload|
      sent = payload
      SendgridClient::Response.new(status: 202, headers: { "x-message-id" => "m-2" })
    end
    delivery = build_delivery(key: "job:5", context: { period: "<script>alert(1)</script>" })

    DeliveryJob.perform_now(delivery.id)

    html = sent[:content].first[:value]
    assert_not_includes html, "<script>"
    assert_includes html, "&lt;script&gt;"
    assert_equal delivery.id.to_s, sent[:personalizations].first[:custom_args][:delivery_id]
  end
end
