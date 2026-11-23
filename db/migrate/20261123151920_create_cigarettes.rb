class CreateCigarettes < ActiveRecord::Migration[8.1]
  def change
    create_table :cigarettes do |t|
      t.integer :quantity_by_day
      t.float :nicotine_mg
      t.references :smokerprofile, null: false, foreign_key: true

      t.timestamps
    end
  end
end
