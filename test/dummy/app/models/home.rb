# A home, whose street is encrypted while the city it stands in is not.
class Home < ApplicationRecord
  belongs_to :contact
  has_many :bookings, dependent: :destroy

  encrypts :street, deterministic: true
end
