module Notifications
  # Decide qué canales usar. En este prototipo solo existen DELIVER y SUPPRESS;
  # COALESCE y el tope de frecuencia son diseño (ver documento técnico).
  class PolicyEngine
    Decision = Struct.new(:action, :channels, :reason, keyword_init: true)

    def self.evaluate(notification_class, recipient:)
      eligible = notification_class.channels - ChannelPreferences.disabled_for(recipient)

      if eligible.empty?
        Decision.new(action: :suppress, channels: [], reason: "NO_ELIGIBLE_CHANNEL")
      else
        Decision.new(action: :deliver, channels: eligible, reason: "ELIGIBLE")
      end
    end
  end
end
