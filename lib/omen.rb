require 'active_job/performs'
require 'anthropic'

require 'omen/attributes'
require 'omen/config'
require 'omen/distance'
require 'omen/grants'
require 'omen/renamed'
require 'omen/time_zone'
require 'omen/bound'
require 'omen/narrowing'
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

  # Said where a database refuses one group, since the groups need nothing from one another.
  REFUSED = 'Skipped, refused by the database: %{statement} (%{error})'

  # @return [Array<String>] the environments whose databases a grant should cover.
  def self.environments = Rails.env.development? ? %w[ development test ] : [Rails.env.to_s]

  # A savepoint each and a warning rather than a raise, so a statement a managed database
  # refuses discards neither the deploy nor the statements behind it -- and what arrives
  # together is applied together, since a table is never left with row level security on and
  # no policy under it.
  # @param connection [ActiveRecord::ConnectionAdapters::AbstractAdapter] a writing one.
  # @param statements [Array<String>] what to run, all of it or none of it.
  # @return [void]
  def self.attempted(connection, *statements)
    connection.transaction(requires_new: true) do
      statements.each { |statement| connection.execute statement }
    end
  rescue ActiveRecord::StatementInvalid => error
    warn REFUSED % { statement: statements.first.squish, error: error.message.lines.first.strip }
  end

  # @yield [ActiveRecord::ConnectionAdapters::AbstractAdapter] a writing connection to each
  #   database this environment prepares.
  # @return [void]
  def self.each_database
    environments.each do |environment|
      config = ActiveRecord::Base.configurations.configs_for env_name: environment,
        name: 'primary'
      next unless config
      ActiveRecord::Tasks::DatabaseTasks.with_temporary_connection(config) { |it| yield it }
    end
  end
end
