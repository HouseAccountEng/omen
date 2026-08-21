# Extends a question and an answer with the prose said in it, in the blocks Claude speaks in.
module Omen::Spoken extend ActiveSupport::Concern
  # @return [String] everything said in prose, which on an answer may be nothing.
  def text = content.select { |block| block['type'] == 'text' }.pluck('text').join "\n"
end
