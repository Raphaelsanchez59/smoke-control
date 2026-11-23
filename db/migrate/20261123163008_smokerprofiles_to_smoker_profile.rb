class SmokerprofilesToSmokerProfile < ActiveRecord::Migration[8.1]
  def change
    rename_table :smokerprofiles , :smoker_profiles
  end
end
