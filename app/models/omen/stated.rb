# Extends Omen::Reading to have a status of its own, rather than one a host shares out.
module Omen::Stated extend ActiveSupport::Concern
  # The states a reading passes through. The reading...
  STATUSES = [
    :unstarted, # ... has been asked something and has nothing back yet (default)
    :started,   # ... is being answered right now, by whichever run holds the claim
    :completed, # ... has been answered, so another question may follow
    :failed,    # ... could not be answered at all, and is the asker's to try again
  ]

  # How long a run holds its claim before another may take the reading over.
  STALLED_AFTER = 10.minutes

  included do
    enum :status, Hash[STATUSES.map { |status| [status, status] }]
  end

private

  def fresh? = updated_at.after? STALLED_AFTER.ago
end
