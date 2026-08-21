# One column a reply asks to be drawn as its parts joined, where the database could not join them.
class Omen::Combination
  # All a reply may declare: a name, the headers to join, and what goes between them.
  SCHEMA = {
    type: 'array',
    description: 'Columns to draw as one, where the database could not build the value itself ' \
                 'because a part of it is encrypted. Empty where nothing needs joining.',
    items: {
      type: 'object', additionalProperties: false, required: %w[ name parts separator ],
      properties: {
        name: { type: 'string', description: 'The header the joined column is drawn under.' },
        parts: { type: 'array', items: { type: 'string' },
                 description: 'Headers of your own query to join, in the order they read.', },
        separator: { type: 'string', description: 'What goes between them, such as ", ".' },
      },
    },
  }

  # @param declared [Array<Hash>] what the reply asked for.
  # @param headers [Array<String>] the headers the rows really have.
  # @return [Array<Omen::Combination>] the ones a row can be drawn through.
  def self.all(declared, headers)
    declared.map { |one| new one }.select { |combination| combination.over? headers }
  end

  # @param declared [Hash] one entry of a reply's `combine`.
  def initialize(declared)
    @declared = declared
  end

  # Answered rather than raised on: the rows are right, and only the presentation was wrong.
  # @param headers [Array<String>] the headers the rows really have.
  # @return [Boolean] whether every part of this names one of them.
  def over?(headers) = parts.any? && parts.all? { |part| headers.include? part }

  # Joins what Omen::Column#read handed back, less the blanks: HIDDEN is a value, NULL is not.
  # @param row [Hash] one row of the answer, decrypted.
  # @return [Hash] the row with the parts replaced, where the first of them stood.
  def applied(row)
    row.each_with_object({}) do |(header, value), into|
      if header == parts.first
        into[name] = parts.filter_map { |part| row[part].presence }.join separator
      elsif parts.exclude? header
        into[header] = value
      end
    end
  end

private

  def name = @declared['name'].to_s

  def parts = Array @declared['parts']

  def separator = @declared['separator'].to_s
end
