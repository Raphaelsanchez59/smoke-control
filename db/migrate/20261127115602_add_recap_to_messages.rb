class AddRecapToMessages < ActiveRecord::Migration[8.1]
  def change
    add_column :messages, :recap, :boolean, default: false
  end
end
