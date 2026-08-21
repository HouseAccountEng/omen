class CreateProviders < ActiveRecord::Migration[8.1]
  def change
    create_table :providers do |t|
      t.string :name, null: false
      t.string :secret
      t.string :access_token
      t.timestamps
    end
  end
end
