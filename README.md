# Omen

You ask Claude a complex question about data stored by your Rails app.
Claude answers with the SQL. Rails runs it.

Omen is an engine that you too can use. You just need a Rails app running on PostgreSQL.
Omen provides the models and the logic to talk to Claude; to parse what it says; to run read-only statements.

Your data never travels. Claude is shown the schema and writes one `SELECT`; Rails runs it and
draws the answer (including encrypted attributes) for whoever asked. Nothing that statement returned is ever sent back.

## How to install

```sh
gem install omen
```

Or, in a `Gemfile`, pinned to the current major:

```ruby
gem 'omen', '~> 0.2'
```

Omen follows [Semantic Versioning](https://semver.org), so `~> major.minor` means `bundle update`
never crosses a breaking change.

## Requirements

**PostgreSQL only** 

<details>
  <summary>This is not a gap waiting to be filled. </summary>
  Two of the guarantees Omen makes are
  Postgres features with no equivalent elsewhere: it identifies an encrypted column by the table OID
  and column number Postgres reports for each result column, which is what stops an alias or an
  expression from laundering one; and it narrows privileges for the statement it runs with
  `SET LOCAL ROLE`, which reverts when the transaction ends. MySQL has `SET ROLE` but nothing
  transaction-scoped, so a raised exception would leave a pooled connection holding the role. Omen
  raises at boot on any other adapter rather than running with a weaker promise.
</details>

**db/schema.rb in Rails** 

<details>
  <summary>Only the :ruby schema is supported. </summary>
  The schema is what Claude is shown, so an app
  on `db/structure.sql` cannot use Omen. Checked at boot and raised on, because copying a
  `structure.sql` to that path fails silently and with teeth: the strip regexes read the Ruby DSL,
  so they match nothing, Omen's own tables stay in the prompt, and Claude is shown the log of every
  question ever asked.
</details>

## Configuration

Installing by adding to your Gemfile and running three commands in your terminal: 

```sh
bin/rails g omen:install # adds three migrations + an initializer you can delete
bin/rails db:migrate     # creates the tables `omen_readings`, `omen_questions`, `omen_answers`
bin/rails db:omen:grant  # set the read-only role statements run as
```

`db:omen:grant` is worth running from the tasks that build a database, so a fresh one is never
missing the role. In `lib/tasks` of the host:

```ruby
granted = Rake::Task['db:omen:grant']

%w[ db:create db:prepare db:reset db:test:prepare ].each do |name|
  Rake::Task[name].enhance do
    granted.reenable
    granted.invoke
  end
end
```

### Requirements

- **A read-only connection role.** `connects_to database: { writing: :primary, reading: :reader }`
  on the record class, with the `reading` entry logging in as a Postgres role granted `SELECT`
  and nothing else. Omen raises rather than falling back to a role that could write, which is
  the point. Creating that role is the app's own business — Omen has no name for it, and
  discovers it when granting.
- **Active Record Encryption keys.** Without them an encrypted column reads back as the
  placeholder rather than as the value, quietly.
- **An `ApplicationJob`.** A reading is answered outside the request, and the job descends
  from the app's own base class.
- **A `db/schema.rb`.** It is the prompt, so a reading cannot happen before the first
  `db:migrate` has dumped one.

### The options

Every setting has a default, so the initializer is optional. `rails generate omen:install`
writes it with each line commented out, as the list of what there is to say.

| Setting | Default |
|---|---|
| `narrow_role` | `'omen_inquirer'` |
| `notes` | none, so the prompt says nothing about this app beyond its schema |

## What a host builds on top

`Omen::Reading` has a `type` column nowhere, so a subclass is a transparent second name for the
same rows: `Inquiry.all` carries no type condition, and `to_partial_path` becomes
`inquiries/inquiry`.

```ruby
class Inquiry < Omen::Reading
  belongs_to :agent
end
```

`Omen::Reading.create! question: 'Where are the homes we serve?'` is the whole of asking; a
follow-up is `reading.ask '...'`. Each question is answered in a job, and the answer carries the
statement Claude wrote, the rows it found, and which header of theirs held an encrypted column.

Two things a subclass cannot reach, because the gem's own class is what a job loads:
`broadcasts_refreshes`, and anything else that has to be declared on `Omen::Reading` itself. One
line in the host does it:

```ruby
Rails.application.config.to_prepare { Omen::Reading.broadcasts_refreshes }
```

## After the first deploy

The narrow role is granted `SELECT` on every table and then refused Omen's own three, which can
only happen once those tables exist. On a database that forbids `CREATE ROLE` — a managed one
usually does — the role is made by hand and the revocation with it:

```sql
REVOKE SELECT ON omen_readings, omen_questions, omen_answers FROM omen_inquirer;
```

A missed table there means Claude is shown the log of every question ever asked.

## License

MIT, see [LICENSE.txt](LICENSE.txt).
