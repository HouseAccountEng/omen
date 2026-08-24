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
end

ActiveSupport.run_load_hooks :omen_reading, Omen::Reading
