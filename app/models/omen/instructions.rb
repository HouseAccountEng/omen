# Everything Claude is told before a question: the prose, the schema, and the shape of a reply.
class Omen::Instructions
  # The prose, kept beside this class so it reads as prose rather than as a string.
  PROSE = File.expand_path 'instructions.md', __dir__

  # The database function a stored timestamp is read through, created by the gem's rake task.
  EASTERN = 'eastern'

  # The one shape a reply may take: both keys required, and no others admitted.
  ANSWER = {
    type: 'object', additionalProperties: false, required: %w[ sql note combine ],
    properties: {
      sql: { type: 'string',
             description: 'The one PostgreSQL SELECT that answers the question, or ' \
                          'empty to ask something first.', },
      note: { type: 'string',
              description: 'A sentence or two: what the query returns and any ' \
                           'assumption made. If sql is empty, the question you ' \
                           'need answered first.', },
      combine: Omen::Combination::SCHEMA,
    },
  }

  # @return [Hash] what a reply is constrained to, so that it always parses.
  def self.output_config = { format_: { type: :json_schema, schema: ANSWER } }

  # Cached for an hour: the schema is thousands of tokens, and refining sends it again.
  # @return [Array<Hash>] the one system block of a request.
  def self.block
    [ { type: 'text', text: new.text, cache_control: { type: 'ephemeral', ttl: '1h' } } ]
  end

  # Today's date is said out loud because "last month" is Claude's to resolve, and it has no clock.
  # @return [String] the prose, with the schema, the subclasses and the host's notes filled in.
  def text
    format File.read(PROSE), today: Date.current.to_fs(:long), eastern: EASTERN,
      schema: schema, types: types, readable: readable, refused: refused,
      notes: Omen.config.notes
  end

private

  def schema = Omen::Schema.new.text

  def types
    Rails.application.eager_load!
    Omen.config.record.descendants.select(&:finder_needs_type_condition?)
      .group_by(&:table_name).sort.map { |table, kinds| "- `#{table}`: #{named kinds}" }.join "\n"
  end

  def named(kinds) = kinds.map(&:name).sort.map { |name| "`#{name}`" }.join ', '

  def readable = named Omen::Column.all.select(&:readable?)

  def refused = named Omen::Column.all.reject(&:readable?)
end
