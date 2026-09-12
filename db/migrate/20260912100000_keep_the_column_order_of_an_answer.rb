class KeepTheColumnOrderOfAnAnswer < ActiveRecord::Migration[8.1]
  def up
    change_column :omen_answers, :result, :json, default: [], null: false
  end
end
