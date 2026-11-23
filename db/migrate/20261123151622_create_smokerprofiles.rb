class CreateSmokerprofiles < ActiveRecord::Migration[8.1]
  def change
    create_table :smokerprofiles do |t|
      t.string :name
      t.string :cigarette_type
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end
  end
end
