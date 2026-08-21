# Somebody whose home is on the books, with the personal data an app of ours encrypts.
class Contact < ApplicationRecord
  has_many :homes, dependent: :destroy

  encrypts :email, deterministic: true, downcase: true
  encrypts :phone, :surname, deterministic: true

  # Not deterministic, so nothing can query it -- which is what makes Omen refuse to draw it.
  encrypts :notes
end
