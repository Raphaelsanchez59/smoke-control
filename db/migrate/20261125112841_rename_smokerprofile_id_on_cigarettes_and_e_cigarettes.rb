class RenameSmokerprofileIdOnCigarettesAndECigarettes < ActiveRecord::Migration[8.1]
  def change
    rename_column :cigarettes, :smokerprofile_id, :smoker_profile_id
    rename_column :e_cigarettes, :smokerprofile_id, :smoker_profile_id
  end
end
