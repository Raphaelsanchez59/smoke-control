class AddChatReferenceToSmokerProfiles < ActiveRecord::Migration[8.1]
  def change
    add_reference :smoker_profiles, :chat, foreign_key: true, index: { unique: true }
  end
end
