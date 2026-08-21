require 'test_helper'

# What a host has to provide for Omen to keep its promises, asserted on the app standing in
# for one. Every other test leans on all three of these.
class DummyTest < ActiveSupport::TestCase
  test 'the app around Omen is PostgreSQL, with a reading role and its columns encrypted' do
    assert_equal 'postgresql', ApplicationRecord.connection_db_config.adapter

    read = ApplicationRecord.connected_to(role: :reading) do
      ApplicationRecord.with_connection { |connection| connection.select_value 'SELECT 1' }
    end
    assert_equal 1, read

    stored = ApplicationRecord.with_connection do |connection|
      connection.select_value "SELECT street FROM homes WHERE apt = 'apt 4'"
    end
    assert_equal '1 Rodeo Dr', homes(:apartment).street
    assert stored.start_with? '{"p":'
  end
end
