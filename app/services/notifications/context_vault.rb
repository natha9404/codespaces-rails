module Notifications
  # Cifra el contexto de la solicitud (context_ciphertext) y calcula el HMAC
  # del destinatario: irreversible, pero permite buscar por email sin guardarlo.
  module ContextVault
    module_function

    def seal(payload)
      encryptor.encrypt_and_sign(payload.to_json)
    end

    def unseal(ciphertext)
      JSON.parse(encryptor.decrypt_and_verify(ciphertext)).with_indifferent_access
    end

    def lookup_hash(recipient)
      key = Rails.application.key_generator.generate_key("notification-recipient-lookup")
      OpenSSL::HMAC.hexdigest("SHA256", key, recipient.to_s.strip.downcase)
    end

    def encryptor
      key = Rails.application.key_generator.generate_key(
        "notification-context", ActiveSupport::MessageEncryptor.key_len
      )
      ActiveSupport::MessageEncryptor.new(key)
    end
  end
end
