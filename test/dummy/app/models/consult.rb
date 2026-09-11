# A reading a provider asks about their own data, which Postgres narrows to their own rows.
class Consult < Omen::Reading
  attribute :provider_id, :integer

  # @return [String] the role granted the columns a provider may read, and nothing else.
  def runs_as = 'omen_dummy_provider'

  # @return [Hash] whose rows those are, which the policy on each of those tables reads.
  def settings = { 'omen.provider_id' => provider_id }
end
