# One column of the schema that Rails encrypts before the database is allowed to store it.
class Omen::Column
  # What stands in for a value this class will not hand over in the clear.
  HIDDEN = '(encrypted)'

  # A word that makes a name a credential's: `secret`, `api_key`, `otp_salt`, never `surname`.
  CREDENTIALS = /secret|key|password|token|pin|salt|credential|signature/

  # @return [Array<Omen::Column>] every encrypted column in the app, one per table and name.
  def self.all
    Rails.application.eager_load!
    Omen.config.record.descendants.flat_map do |model|
      model.encrypted_attributes.to_a.map { |attribute| new model, attribute }
    end.uniq(&:name)
  end

  # An alias in the statement cannot change what Postgres says a value came from.
  # @param result [PG::Result] what the statement answered.
  # @param connection [ActiveRecord::ConnectionAdapters::AbstractAdapter] the one it ran on.
  # @return [Hash] each header of the result that is an encrypted column, to that column's name.
  def self.of(result, connection)
    sources = all.index_by { |column| column.source connection }
    result.nfields.times.each_with_object({}) do |index, into|
      found = sources[[ result.ftable(index), result.ftablecol(index) ]]
      into[result.fname index] = found.name if found
    end
  end

  # @param model [Class] an Active Record that encrypts the column.
  # @param attribute [Symbol] the attribute it encrypts.
  def initialize(model, attribute)
    @model = model
    @attribute = attribute
  end

  # @return [String] the table and column, as Postgres names the source of a value.
  def name = "#{@model.table_name}.#{@attribute}"

  # @return [Boolean] whether a value of this column may be shown in the clear.
  def readable? = !CREDENTIALS.match?(@attribute) && type.scheme.deterministic?

  # @return [Array<Integer>] the table OID and column number Postgres reports for this column.
  def source(connection)
    described = connection.raw_connection.exec_params probe, []
    [ described.ftable(0), described.ftablecol(0) ]
  end

  # @return [String, nil] the plaintext, or the placeholder where there is none to be had.
  def read(value)
    readable? ? type.deserialize(value) : HIDDEN
  rescue ActiveRecord::Encryption::Errors::Decryption
    HIDDEN
  end

private

  def type = @model.type_for_attribute @attribute

  def probe = @model.select(@attribute).limit(0).to_sql
end
