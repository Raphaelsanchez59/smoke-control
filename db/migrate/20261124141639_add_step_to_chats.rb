class AddStepToChats < ActiveRecord::Migration[8.1]
  def change
    add_column :chats, :step, :string, default: "smoker"
  end
end
