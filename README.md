# Omen

Staff ask Claude a question about the data an app holds; Claude writes the SQL, Rails runs it.

Omen ships the models and the logic to talk to Claude, parse what it says back, and run the
statement it wrote against a read-only connection. It ships **no controllers, routes or views** —
the pages belong to the app that installs it.

> **0.1.0 does nothing yet.** This release loads as a Rails engine. The models
> and the Claude logic land in a later version. The requirements below are what it will need, and
> are stated now so nobody installs it into an app it cannot work in.

## How to install

```sh
gem install omen
```

Or, in a `Gemfile`, pinned to the current major:

```ruby
gem 'omen', '~> 0.1'
```

Omen follows [Semantic Versioning](https://semver.org), so `~> major.minor` means `bundle update`
never crosses a breaking change.

## Requirements

**PostgreSQL only.** This is not a gap waiting to be filled. Two of the guarantees Omen makes are
Postgres features with no equivalent elsewhere: it identifies an encrypted column by the table OID
and column number Postgres reports for each result column, which is what stops an alias or an
expression from laundering one; and it narrows privileges for the statement it runs with
`SET LOCAL ROLE`, which reverts when the transaction ends. MySQL has `SET ROLE` but nothing
transaction-scoped, so a raised exception would leave a pooled connection holding the role. Omen
raises on any other adapter rather than running with a weaker promise.

**`db/schema.rb`, in Rails' `:ruby` schema format.** The schema is what Claude is shown, so an app
on `db/structure.sql` cannot use Omen. This is checked at boot rather than left to fail later.

**A read-only connection.** Omen runs every statement through a Rails connection role that cannot
write, and raises rather than falling back to a writable one.

## License

MIT, see [MIT-LICENSE](MIT-LICENSE).
