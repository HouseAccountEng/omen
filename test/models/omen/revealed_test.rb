require 'test_helper'

# What a page is drawn from: the plaintext behind an encrypted column, and the parts joined.
class Omen::RevealedTest < ActiveSupport::TestCase
  # DO NOT DELETE. The one provider fixture that has a secret, so a page can be shown never to
  # draw it, whether it was asked for on its own or as part of a column somebody joined.
  SECRET = 'S3cr3t'

  test 'an encrypted column is read back, and an expression over one is held back' do
    said = answered "SELECT street FROM homes WHERE apt = 'apt 4'"
    assert_equal '1 Rodeo Dr', said.shown.sole['street']
    assert_not_includes said.shown.to_s, '{"p":'

    shouted = answered 'SELECT upper(street) AS shouted FROM homes'
    assert_equal [ Omen::Column::HIDDEN ] * 2, shouted.shown.pluck('shouted')
  end

  test 'a credential is refused however it is asked for, and the row says so' do
    said = answered 'SELECT name, secret FROM providers WHERE secret IS NOT NULL'

    assert_equal Omen::Column::HIDDEN, said.shown.sole['secret']
    assert_not_includes said.shown.to_s, SECRET
  end

  # The join happens after Omen::Column#read, which is what keeps a credential out of it.
  test 'a combination over a credential joins the placeholder, never the value' do
    said = answered 'SELECT name, secret FROM providers WHERE secret IS NOT NULL',
      combine: [ { name: 'who', parts: %w[ name secret ], separator: ' / ' } ]

    assert_equal "Local Handyman / #{Omen::Column::HIDDEN}", said.shown.sole['who']
    assert_not_includes said.shown.to_s, SECRET
  end

  test 'a combination draws the parts of an address as one column, decrypted' do
    said = answered "SELECT street, city FROM homes WHERE apt = 'apt 4'",
      combine: [ { name: 'address', parts: %w[ street city ], separator: ', ' } ]

    assert_equal '1 Rodeo Dr, Beverly Hills', said.shown.sole['address']
  end

  # An answer stored before a key rotation cannot be read back, and the page says so rather
  # than drawing what it could not decrypt.
  test 'a row whose plaintext no longer decrypts draws the placeholder' do
    said = Omen::Answer.new result: [ { 'street' => 'plaintext left behind' } ],
      provenance: { 'street' => 'homes.street' }

    assert_equal Omen::Column::HIDDEN, said.shown.sole['street']
  end

  test 'a page draws no more rows than it says it will, however many came back' do
    said = answered 'SELECT generate_series(1, 500) AS n'

    assert_equal Omen.config.maximum_rows, said.shown.size
    assert said.truncated?
  end

private

  def answered(sql, combine: [])
    spoken = { sql: sql, note: 'Whatever it is.', combine: combine }.to_json
    Omen::Answer.new content: [ { 'type' => 'text', 'text' => spoken } ],
      **Omen::Query.new(sql).answer
  end
end
