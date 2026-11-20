module Notifications
  # Reemplazo en memoria de las preferencias de canal del usuario.
  # En Buk esto vendría del perfil real; aquí permite probar la política.
  module ChannelPreferences
    class << self
      def disable!(recipient, channel)
        store[recipient.to_s.downcase] |= [ channel.to_sym ]
      end

      def disabled_for(recipient)
        store[recipient.to_s.downcase]
      end

      def reset!
        @store = nil
      end

      private

      def store
        @store ||= Hash.new { |hash, key| hash[key] = [] }
      end
    end
  end
end
