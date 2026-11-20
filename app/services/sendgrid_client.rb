# Cliente SIMULADO de SendGrid: este repositorio no hace llamadas de red.
# El transporte es inyectable para probar rechazos y timeouts.
class SendgridClient
  Response = Struct.new(:status, :headers, keyword_init: true)

  DEFAULT_TRANSPORT = lambda do |_path, _payload|
    Response.new(status: 202, headers: { "x-message-id" => "sim-#{SecureRandom.hex(6)}" })
  end

  class << self
    attr_writer :transport

    def transport = @transport || DEFAULT_TRANSPORT

    def reset! = @transport = nil

    def post(path, **payload) = transport.call(path, payload)
  end
end
