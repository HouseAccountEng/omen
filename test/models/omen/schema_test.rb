require 'test_helper'

class Omen::SchemaTest < ActiveSupport::TestCase
  test "Claude is shown the app's own schema, less the tables a reading is kept in" do
    shown = Omen::Schema.new.text

    assert_includes shown, 'create_table "homes"'
    assert_includes shown, 'add_foreign_key "homes", "contacts"'
    Omen.tables.each { |table| assert_not_includes shown, table }
    assert_not_includes shown, 'add_foreign_key "omen_questions"'
  end

  test 'an enum only the cut tables used goes with them, and one another table shares stays' do
    shown = Omen::Schema.new.text

    assert_includes shown, 'create_enum "booking_status"'
    assert_not_includes shown, 'create_enum "omen_status"'
  end

  test 'a unique index says something about the rows and stays; a plain one is dropped' do
    shown = Omen::Schema.new.text

    assert_includes shown, 'index_contacts_on_email'
    assert_includes shown, 'unique: true'
    assert_not_includes shown, 'index_homes_on_contact_id'
  end
end
