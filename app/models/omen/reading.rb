# A thread of questions somebody asks Claude about the data this app holds.
class Omen::Reading < Omen.config.record
  include Omen::Asked, Omen::Executed, Omen::Stated

  has_many :questions, -> { order :id }, dependent: :destroy

  # What the reading is opened with: a reading nobody asked anything is a reading of nothing.
  attribute :question, :string

  validates :question, presence: true, on: :create

  after_create -> { ask question }

  performs :run

  # @return [String] the default representation (used in views).
  def to_s = questions.first&.text.to_s.truncate 80

  # @return [String] Postgres role the statement runs as, which holds what it may read.
  def runs_as = Omen.config.narrow_role

  # @return [Hash] what is set before the statement, for a row policy of the host's to read.
  def settings = {}

  # @return [String] the host's notes about its data, as this reading's asker is told them.
  def notes = Omen.config.notes
end

ActiveSupport.run_load_hooks :omen_reading, Omen::Reading
