# Changelog

All notable changes to this project will be documented in this file.

For more information about changelogs, check [Keep a Changelog](http://keepachangelog.com) and
[Vandamme](http://tech-angels.github.io/vandamme).

## [Unreleased]

## 0.3.1 - 2026-08-24

* [Fix] Stop asserting the role attributes only a superuser may set, since `NOSUPERUSER`,
  `NOBYPASSRLS` and `NOREPLICATION` are refused outright by every managed database -- a role is
  created without them anyway, so they are read back and warned about rather than set
* [Fix] Run each statement of the grant in a savepoint of its own, so one a database refuses no
  longer discards the grants, the revocations and both functions behind it

## 0.3.0 - 2026-08-24

* [Feature] Create a `miles_between(lat1, lng1, lat2, lng2)` function and name it in the prompt,
  so a radius is four arguments rather than a dozen nested trigonometric calls that a reply
  balances by hand -- and gets wrong
* [Fix] Tell Claude that text is single-quoted and an apostrophe inside it is doubled, since a
  double-quoted literal is read as a column name and refuses the whole statement
* [Fix] Tell Claude to declare a `combine` where an encrypted value belongs inside a sentence,
  rather than returning the pieces as columns for the page to draw apart

## 0.2.2 - 2026-08-24

* [Fix] Run a load hook as each model loads, so a host declares `broadcasts_refreshes` and the
  rest through `ActiveSupport.on_load :omen_reading` rather than by naming the class while
  initializers run, which loaded Active Record before Rails was up
* [Fix] Read the adapter through the `:active_record` load hook, so a boot that never touches
  the database is not the boot that loads it early

## 0.2.1 - 2026-08-24

* [Fix] Declare `eastern()` over an instant as well as a stored timestamp, so a reply that
  reaches for `now()` finds a function rather than `does not exist`
* [Fix] Tell Claude not to ask the database what time it is, since the prompt already says
  what today is
* [Fix] Point RubyGems at the API reference, so a gem page and a gem listing say the same
  thing about where the documentation is

## 0.2.0 - 2026-08-21

* [Feature] Ask Claude a question about an app's own data, and run the SQL it writes against a
  read-only connection: three models, the prompt, the narrow role and the function a timestamp
  is read through, an install generator, and no controllers, routes or views

## 0.1.0 - 2026-08-21

* [Feature] An engine that loads and does not do anything yet
