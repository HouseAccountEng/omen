class CreateOmenAnswers < ActiveRecord::Migration[8.1]
  def change
    create_table :omen_answers do |t|
      t.jsonb :content, default: [], null: false
      t.jsonb :result, default: [], null: false
      t.jsonb :provenance, default: {}, null: false
      t.integer :input_usage, default: 0, null: false
      t.integer :output_usage, default: 0, null: false
      t.references :question, null: false, index: { unique: true },
        foreign_key: { to_table: :omen_questions }
      t.string :stop_reason
      t.string :error
      t.timestamps
    end
  end
end
