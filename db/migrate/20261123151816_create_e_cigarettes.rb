class CreateECigarettes < ActiveRecord::Migration[8.1]
  def change
    create_table :e_cigarettes do |t|
      t.integer :puff_by_day
      t.float :nicotine_mg
      t.references :smokerprofile, null: false, foreign_key: true

      t.timestamps
    end
  end
end
