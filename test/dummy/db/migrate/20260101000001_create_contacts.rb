class CreateContacts < ActiveRecord::Migration[8.1]
  def change
    create_table :contacts do |t|
      t.string :name, null: false
      t.string :email
      t.string :phone
      t.string :surname
      t.text :notes
      t.timestamps

      t.index :email, unique: true
    end
  end
end
