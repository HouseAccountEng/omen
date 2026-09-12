# A reading a provider asks about their own data, which Postgres narrows to their own rows.
class Consult < Omen::Reading
  attribute :provider_id, :integer

  narrows 'omen_dummy_provider', by: :provider_id,
    own: { 'providers' => 'id = %{owner}',
           'bookings' => 'provider_id = %{owner}',
           'homes' => 'EXISTS (SELECT 1 FROM bookings WHERE bookings.home_id = homes.id)', },
    whole: %w[ contacts ], except: /\Anotes\z/
end
