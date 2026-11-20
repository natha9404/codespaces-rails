class SendgridEmailAdapter
  def deliver!(delivery_id:, recipient:, title:, body:)
    res = SendgridClient.post("/v3/mail/send",
      personalizations: [ { to: [ { email: recipient } ], custom_args: { delivery_id: delivery_id.to_s } } ],
      from: { email: "notificaciones@buk.cl", name: "Buk" }, subject: title,
      content: [ { type: "text/html", value: HtmlEscaper.escape(body) } ])
    raise ProviderRejected unless res.status.to_i == 202
    { status: :accepted, provider_message_id: res.headers["x-message-id"] }
  end
end
