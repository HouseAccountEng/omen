# Somebody who does the work, holding the two credentials Omen will never draw.
class Provider < ApplicationRecord
  encrypts :secret, :access_token, deterministic: true
end
