class CreateOmenQuestions < ActiveRecord::Migration[8.1]
  def change
    create_table :omen_questions do |t|
      t.jsonb :content, default: [], null: false
      t.references :reading, null: false, foreign_key: { to_table: :omen_readings }
      t.timestamps
    end
  end
end
