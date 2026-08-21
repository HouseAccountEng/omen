# A job asked for at a home, told from an estimate by its type column.
class Booking < ApplicationRecord
  # The states a booking passes through. The job...
  STATUSES = [
    :draft,     # ... has been asked for and not yet done
    :fulfilled, # ... has been done
  ]

  belongs_to :home

  enum :status, Hash[STATUSES.map { |status| [status, status] }]
end
