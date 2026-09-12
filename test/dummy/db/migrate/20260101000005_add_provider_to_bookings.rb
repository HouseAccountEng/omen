class AddProviderToBookings < ActiveRecord::Migration[8.1]
  def change
    add_reference :bookings, :provider, foreign_key: true
  end
end
