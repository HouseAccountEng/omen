# The one shape a reply may take, which is what makes every reply parse.
class Omen::Reply
  # Both keys required, and no others admitted.
  SHAPE = {
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
  def self.output_config = { format_: { type: :json_schema, schema: SHAPE } }
end
