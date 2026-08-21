## What this app is

A stand-in for an app that keeps homes on the books and sends somebody out to work on them.

## Where a table's rows are

A booking does not carry its own geography: it reaches the city through `bookings.home_id` to
`homes`, and the person who asked for it through `homes.contact_id` to `contacts`.
