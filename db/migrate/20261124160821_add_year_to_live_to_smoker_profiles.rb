class AddYearToLiveToSmokerProfiles < ActiveRecord::Migration[8.1]
  def change
    add_column :smoker_profiles, :years_to_live, :integer
  end
end
