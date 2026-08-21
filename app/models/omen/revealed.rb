# Extends Omen::Answer with the plaintext behind the encrypted columns of its rows.
module Omen::Revealed extend ActiveSupport::Concern
  # How Rails' encryption opens an envelope, in either case an expression may have left it in.
  CIPHERTEXT = [ '{"p":', '{"P":' ]

  # @return [Array<Hash>] the rows of the answer a page shows, read back where that is allowed.
  def shown
    @shown ||= result.first(Omen.config.maximum_rows).map { |row| combined revealed row }
  end

private

  def combined(row) = combinations.inject(row) { |left, one| one.applied left }

  def combinations = @combinations ||= Omen::Combination.all(combine, result.first.to_h.keys)

  def revealed(row) = row.to_h { |header, value| [ header, plain(header, value) ] }

  def plain(header, value)
    if (column = columns[provenance[header]])
      column.read value
    elsif value.to_s.start_with?(*CIPHERTEXT)
      Omen::Column::HIDDEN
    else
      value
    end
  end

  def columns = @columns ||= Omen::Column.all.index_by(&:name)
end
