module Omen
  # What an app has to be for this gem to keep its promises, checked as that app boots. Both
  # of these rule an app out rather than inconveniencing it, so neither is worth deferring.
  module Requirements
    # Raised where an app cannot be one this gem works in, however else it is configured.
    class Unmet < StandardError; end

    # The one adapter that reports the table a result column came from, and scopes a role to
    # a transaction. Everything else Omen promises rests on one of those two.
    ADAPTER = 'postgresql'

    # The one schema format that can be read as a prompt.
    FORMAT = :ruby

    # Said where the app reaches its database through anything else.
    WRONG_ADAPTER = 'Omen needs a postgresql database, and this app names the adapter'

    # Said where the app dumps its schema as SQL, which cannot be shown to Claude.
    WRONG_FORMAT = 'Omen shows Claude db/schema.rb, so config.active_record.schema_format ' \
                   'has to be :ruby, and this app sets'

    # Said where the file is not there at all: a run would fail one question at a time, and
    # a structure.sql copied to that path would leave the reading tables in the prompt.
    NO_SCHEMA = 'Omen shows Claude the schema Rails dumps, and there is no file at'

    # @param adapter [String, nil] what this app reaches its own database through.
    # @param schema_format [Symbol] the format it dumps its schema in.
    # @param schema [Pathname] where that dump is kept.
    # @return [void]
    def self.met(adapter:, schema_format:, schema:)
      raise Unmet, "#{WRONG_ADAPTER} #{adapter.inspect}" unless adapter == ADAPTER
      raise Unmet, "#{WRONG_FORMAT} #{schema_format.inspect}" unless schema_format == FORMAT
      raise Unmet, "#{NO_SCHEMA} #{schema}" unless File.exist? schema
    end
  end
end
