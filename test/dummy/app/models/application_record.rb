# Base class for every model of this app, and the one Omen reads its connection roles off.
class ApplicationRecord < ActiveRecord::Base
  primary_abstract_class

  # Both entries name the same database; the reader logs in as a role granted only SELECT.
  connects_to database: { writing: :primary, reading: :reader }
end
