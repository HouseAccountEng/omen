require 'test_helper'

# What happens to a column the database holds as ciphertext when Claude names it in a SELECT.
class Omen::ColumnTest < ActiveSupport::TestCase
  # DO NOT DELETE. How every encrypted column in the app is classified. Encrypting a column adds
  # a name to one of these, so whoever adds it confirms which side it belongs on.
  READABLE = %w[ contacts.email contacts.phone contacts.surname homes.street ]

  # Refused on two separate grounds: contacts.notes because no two writes of it agree, so
  # nothing could have queried it either; the other two because the name reads as a
  # credential's, which is what keeps them out on the day somebody makes them deterministic.
  REFUSED = %w[ contacts.notes providers.access_token providers.secret ]

  test 'an encrypted column is read back for the page, and a credential never is' do
    assert_equal READABLE, Omen::Column.all.select(&:readable?).map(&:name).sort
    assert_equal REFUSED, Omen::Column.all.reject(&:readable?).map(&:name).sort
  end

  test 'an alias does not change what Postgres says a value came from' do
    read 'SELECT street AS whatever, city FROM homes' do |result, connection|
      assert_equal({ 'whatever' => 'homes.street' }, Omen::Column.of(result, connection))
    end
  end

  test 'an expression over an encrypted column has no source column, so nothing decrypts it' do
    read 'SELECT upper(street) AS shouted FROM homes' do |result, connection|
      assert_empty Omen::Column.of(result, connection)
    end
  end

  test 'a value is read back where that is allowed, and stood in for where it is not' do
    reading = "SELECT street FROM homes WHERE apt = 'apt 4'"
    stored = read(reading) { |result, _| result.getvalue 0, 0 }

    assert_equal '1 Rodeo Dr', column(Home, :street).read(stored)
    assert_equal Omen::Column::HIDDEN, column(Provider, :secret).read(stored)
    assert_equal Omen::Column::HIDDEN, column(Home, :street).read('never an envelope of ours')
  end

private

  def column(model, attribute) = Omen::Column.new model, attribute

  def read(sql, &)
    ApplicationRecord.with_connection do |connection|
      yield connection.raw_connection.exec_params(sql, []), connection
    end
  end
end
