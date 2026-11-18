class GenerateNotificationContentJob < ApplicationJob
  queue_as :ai_generation

  def perform(request_id)
    # La generación de contenido con IA se implementa en la siguiente iteración.
  end
end
