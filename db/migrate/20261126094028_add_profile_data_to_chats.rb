class AddProfileDataToChats < ActiveRecord::Migration[8.1]
  def change
      add_column :chats, :profile_data, :jsonb, default: {}, null: false
  end
end
