class CreateBookings < ActiveRecord::Migration[8.1]
  def change
    create_enum :booking_status, Booking::STATUSES

    create_table :bookings do |t|
      t.string :type
      t.enum :status, enum_type: :booking_status, default: 'draft', null: false
      t.references :home, null: false, foreign_key: true
      t.timestamps
    end
  end
end
