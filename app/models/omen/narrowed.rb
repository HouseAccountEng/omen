# Extends Omen::Reading with the audience it is asked by: what that audience may read, and the
# Postgres role that holds it there.
module Omen::Narrowed extend ActiveSupport::Concern
  included do
    # What this kind of reading is held to, where a host declared one.
    class_attribute :narrowing
  end

  class_methods do
    # Declares what a reading of this kind may read, which db:omen:grant then writes.
    # @param role [String] the Postgres role its statement runs as.
    # @param by [Symbol] the column of the reading that says whose rows these are.
    # @param own [Hash] every table it reads rows of, to what makes a row its own -- written
    #   with `%{owner}`, which stands for whoever the reading names.
    # @param whole [Array<String>] the tables it reads whole, nobody's in particular.
    # @param except [Regexp, nil] the columns of those it may not read.
    # @return [void]
    def narrows(role, by:, own:, whole: [], except: nil)
      self.narrowing = Omen::Narrowing.new role: role, by: by, own: own, whole: whole,
        except: except
    end

    # @return [Array<Omen::Narrowing>] every one a host has declared, over every kind of reading.
    def narrowings
      Rails.application.eager_load!
      descendants.filter_map(&:narrowing).uniq
    end
  end

  # @return [String] Postgres role the statement runs as, which holds what it may read.
  def runs_as = narrowing&.role || Omen.config.narrow_role

  # @return [Hash] what is set before the statement, for a row policy of the host's to read.
  def settings = narrowing ? { narrowing.setting => self[narrowing.by] } : {}
end
