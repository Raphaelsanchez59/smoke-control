class Users::RegistrationsController < Devise::RegistrationsController
  # Préremplit le formulaire d'inscription avec les réponses du chat de l'invité
  def new
    super do |user|
      chat = Chat.find_by(id: session[:chat_id], user_id: nil)
      next unless chat

      profile_data = chat.profile_data
      user.nickname = profile_data["nickname"] if user.nickname.nil?
      if user.birth_date.nil? && profile_data["birth_year"].present?
        user.birth_date = Date.new(profile_data["birth_year"].to_i, 1, 1)
      end
      user.start_smoking_year = profile_data["start_smoking_year"] if user.start_smoking_year.nil?
    end
  end
end
