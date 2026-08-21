# What Claude writes its SQL against: the app's own schema, less the tables a reading is kept in.
class Omen::Schema
  # A plain index is a note about speed; a unique one is a fact about the rows, so it stays.
  HINT = /^\s*t\.index (?!.*unique: true).*\n/

  # @return [String] the schema, without this feature's own tables, their keys or their enum.
  def text = without_orphan_enums hidden.inject(source) { |left, name| without_table left, name }

private

  def source = File.read(Omen.config.schema).gsub HINT, ''

  def hidden = Omen.tables

  def without_table(text, name)
    text.gsub(/^  create_table "#{name}".*?\n  end\n\n?/m, '')
      .gsub(/^  add_foreign_key ("#{name}"|"\w+", "#{name}").*\n/, '')
  end

  def without_orphan_enums(text)
    # Derived rather than named, so a type the cut tables shared with another survives
    text.gsub(/^  create_enum "(\w+)".*\n/) do |line|
      text.include?(%(enum_type: "#{Regexp.last_match 1}")) ? line : ''
    end
  end
end
