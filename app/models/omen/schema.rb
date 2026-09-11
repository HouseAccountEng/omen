# What Claude writes its SQL against: the app's own schema, less what the role may not read.
class Omen::Schema
  # A plain index is a note about speed; a unique one is a fact about the rows, so it stays.
  HINT = /^\s*t\.index (?!.*unique: true).*\n/

  # @param role [String] the Postgres role the statement will run as.
  def initialize(role)
    @role = role
  end

  # @return [String] the schema, without a table or a column the role is refused, and without
  #   an enum or a foreign key left behind by one.
  def text = without_orphan_enums without_columns without_tables source

private

  def source = File.read(Omen.config.schema).gsub HINT, ''

  def refusal = Omen::Refusal.new @role

  def without_tables(text)
    refusal.tables.inject(text) { |left, name| without_table left, name }
  end

  def without_columns(text)
    refusal.columns.inject(text) { |left, (table, column)| without_column left, table, column }
  end

  def without_table(text, name)
    text.gsub(/^  create_table "#{name}".*?\n  end\n\n?/m, '')
      .gsub(/^  add_foreign_key ("#{name}"|"\w+", "#{name}").*\n/, '')
  end

  def without_column(text, table, column)
    text.sub(/^  create_table "#{table}".*?\n  end\n/m) do |block|
      block.gsub(/^    t\.\w+ "#{column}".*\n/, '')
        .gsub(/^    t\.index \[[^\]]*"#{column}".*\n/, '')
    end
  end

  def without_orphan_enums(text)
    # Derived rather than named, so a type the cut tables shared with another survives
    text.gsub(/^  create_enum "(\w+)".*\n/) do |line|
      text.include?(%(enum_type: "#{Regexp.last_match 1}")) ? line : ''
    end
  end
end
