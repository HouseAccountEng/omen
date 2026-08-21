class CreateHomes < ActiveRecord::Migration[8.1]
  def change
    create_table :homes do |t|
      t.string :city, null: false
      t.references :contact, null: false, foreign_key: true
      t.string :street
      t.string :apt
      t.date :occupied_on
      t.timestamps
    end
  end
end
