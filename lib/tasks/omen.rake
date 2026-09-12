namespace :db do
  namespace :omen do
    desc 'Create the role a reading runs its statement as, the function it reads a ' \
         'timestamp through, and the policies every narrowing a host declared asks for'
    task grant: :environment do
      Omen::Inquirer.grant
    end

    desc 'Take every narrowing back off, leaving each table read the way it was read before'
    task widen: :environment do
      Omen::Inquirer.widen
    end

    desc 'Say which roles the policies of a narrowing hold back, membership included'
    task narrowed: :environment do
      Omen.config.record.with_connection do |connection|
        Omen::Bound.roles(connection).each { |row| puts row.join ' ' }
        surprises = Omen::Bound.surprises connection
        abort "Narrowed without being asked for: #{surprises.inspect}" if surprises.any?
      end
    end
  end
end
