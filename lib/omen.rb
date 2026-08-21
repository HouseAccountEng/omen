require 'active_job/performs'
require 'anthropic'

require 'omen/config'
require 'omen/eastern'
require 'omen/inquirer'
require 'omen/requirements'
require 'omen/version'
require 'omen/engine'

# Staff ask Claude a question about the data an app holds; Claude writes the SQL, Rails runs it.
module Omen
  # Hidden twice over: out of the prompt, and out of what the statement's own role may read.
  # @return [Array<String>] the tables this feature keeps its log of questions and answers in.
  def self.tables = [ Omen::Reading, Omen::Question, Omen::Answer ].map(&:table_name)

  # @return [Omen::Config] everything this feature has to be told about the app around it.
  def self.config = @config ||= Omen::Config.new

  # Yields the configuration, so a host states its own facts in one initializer.
  # @return [void]
  def self.configure = yield config
end
