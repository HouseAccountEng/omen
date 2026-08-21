class CreateOmenReadings < ActiveRecord::Migration[8.1]
  def change
    create_enum :omen_status, Omen::Stated::STATUSES

    create_table :omen_readings do |t|
      t.enum :status, enum_type: :omen_status, default: Omen::Stated::STATUSES.first, null: false
      t.integer :input_usage, default: 0, null: false
      t.integer :output_usage, default: 0, null: false
      t.integer :questions_count, default: 0, null: false
      t.timestamps
    end
  end
end
