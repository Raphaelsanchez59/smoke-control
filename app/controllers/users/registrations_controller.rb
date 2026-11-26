class Users::RegistrationsController < Devise::RegistrationsController
  # Préremplit le formulaire d'inscription avec les réponses du chat de l'invité
  def new
    super do |user|
      chat = Chat.find_by(id: session[:chat_id], user_id: nil)
      if chat
        user.birth_date ||= chat.answered_birth_date
        user.start_smoking_year ||= chat.answered_start_year
      end
    end
  end
end
