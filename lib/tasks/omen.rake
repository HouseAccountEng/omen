namespace :db do
  namespace :omen do
    desc 'Create the role a reading runs its statement as, and the function it reads a ' \
         'timestamp through'
    task grant: :environment do
      Omen::Inquirer.grant
    end
  end
end
