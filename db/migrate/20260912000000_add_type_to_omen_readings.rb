class AddTypeToOmenReadings < ActiveRecord::Migration[8.1]
  def change
    add_column :omen_readings, :type, :string
    add_index :omen_readings, :type
  end
end
