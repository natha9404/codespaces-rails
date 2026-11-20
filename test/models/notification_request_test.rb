require "test_helper"

class NotificationRequestTest < ActiveSupport::TestCase
  test "acepta los estados de admisión del diseño" do
    NotificationRequest::STATUSES.each do |status|
      request = NotificationRequest.new(idempotency_key: "k-#{status}", status: status)
      assert request.valid?, "#{status} debería ser válido"
    end
  end

  test "rechaza estados fuera del diseño" do
    request = NotificationRequest.new(idempotency_key: "k-x", status: "SENT")
    assert_not request.valid?
  end

  test "exige idempotency_key" do
    request = NotificationRequest.new(status: "RECEIVED")
    assert_not request.valid?
  end
end
