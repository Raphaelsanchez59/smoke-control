class Addfieldstousers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :nickname, :string
    add_column :users, :birth_date, :date
    add_column :users, :start_smoking_year, :integer
  end
end
