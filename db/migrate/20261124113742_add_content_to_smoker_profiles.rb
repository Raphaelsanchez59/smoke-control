class AddContentToSmokerProfiles < ActiveRecord::Migration[8.1]
  def change
    add_column :smoker_profiles, :content, :text
  end
end
