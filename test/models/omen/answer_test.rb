require 'test_helper'

class Omen::AnswerTest < ActiveSupport::TestCase
  # DO NOT DELETE, and do not retype: the two characters this holds are a backslash and a `u`,
  # and a tool that writes them as the character they stand for leaves a test that passes with
  # the decoding in Omen::Answer#note reverted. Read the file's bytes back before trusting it.
  ESCAPE = '\u2013'

  # A real payload: Claude escaped the backslash of its own escape, so JSON.parse kept both.
  test 'an escape Claude wrote twice over reads as the character it stands for' do
    said = answered note: "Before I write this: the Feb#{ESCAPE}Apr jobs are the ones you mean?"

    assert_equal 'Before I write this: the Feb–Apr jobs are the ones you mean?', said.note
    assert_not_includes said.note, 'u2013'
  end

  test 'an answer carries the one statement Claude wrote, and the joins it asked for' do
    said = answered sql: 'SELECT city FROM homes', note: 'Every city.',
      combine: [ { 'name' => 'address', 'parts' => %w[ street city ], 'separator' => ', ' } ]

    assert_equal 'SELECT city FROM homes', said.sql
    assert_equal 'Every city.', said.note
    assert_equal 'address', said.combine.sole['name']
    assert_equal 'assistant', said.role
    assert_not said.cut_off?
  end

  test 'an answer says it ran past the page where one row more than the cap came back' do
    capped = Array.new Omen.config.maximum_rows, {}

    assert_not Omen::Answer.new(result: capped).truncated?
    assert Omen::Answer.new(result: capped + [ {} ]).truncated?
  end

private

  def answered(sql: '', note: '', combine: [])
    text = { sql: sql, note: note, combine: combine }.to_json
    Omen::Answer.new content: [ { 'type' => 'text', 'text' => text } ]
  end
end
