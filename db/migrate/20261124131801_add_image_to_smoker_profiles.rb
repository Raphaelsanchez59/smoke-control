class AddImageToSmokerProfiles < ActiveRecord::Migration[8.1]
  def change
    add_column :smoker_profiles, :image, :string
  end
end
