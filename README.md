# Omen

You ask Claude a complex question about the data your Rails app already holds.
Claude answers with the SQL. Rails runs it.

<!-- The demo goes here. Drop the recording in as demo.gif at the root of the repo and
     uncomment the line below:

![Asking Omen a question inside a Rails app](demo.gif)
-->

Your data never travels. Claude is shown the schema and writes one `SELECT`; Rails runs it
read-only and draws the answer -- encrypted columns included -- for whoever asked. Nothing that
statement returned is ever sent back.

## Running it

In your `Gemfile`, pinned to the current minor while this is still below 1.0:

```ruby
gem 'omen', '~> 0.4.0'
```

Then four commands:

```sh
bin/rails g omen:install   # three migrations and an initializer you may delete
bin/rails db:migrate       # omen_readings, omen_questions, omen_answers
bin/rails db:omen:grant    # the read-only role a statement runs as, and three functions
bin/rails g omen:pages     # a model, a controller, three views and a route, all yours
```

`bin/rails s`, then `/inquiries`. Type a question and the answer arrives under it, with the
statement Claude wrote and the rows it found.

## What your app has to have first

None of it is Omen's to create, and each is checked rather than assumed:

- **PostgreSQL**, and a `db/schema.rb` rather than a `structure.sql`. Both are raised on at boot.
- **A read-only connection role**: `connects_to database: { writing: :primary, reading: :reader }`
  on `ApplicationRecord`, where `reader` logs in as a Postgres role granted `SELECT` and nothing
  else. Omen raises rather than falling back to a role that could write, which is the point.
- **`ANTHROPIC_API_KEY`**, or a key named in the initializer.
- **Active Record Encryption keys**, without which an encrypted column reads back as a
  placeholder rather than as its value, quietly.
- **An `ApplicationJob`**, since a reading is answered outside the request.

## What you get

`Omen::Reading.create! question: 'Where are the homes we serve?'` is the whole of asking, and
`reading.ask '...'` is a follow-up. Each question is answered in a job, and the answer carries
the statement Claude wrote, the rows it found, and which of their headers held an encrypted
column. `rails g omen:pages` writes the pages that draw all of that, into your app, for you to
keep or replace.

## Everything else

[INSTRUCTIONS.md](INSTRUCTIONS.md) has the reasoning: why Postgres and no other adapter, what
`db:omen:grant` creates and what to do on a managed database that forbids it, every setting and
its default, what the generated pages get right and why, and what a host can build on top.

## License

MIT, see [LICENSE.txt](LICENSE.txt).
