require_relative 'lib/omen/version'

Gem::Specification.new do |spec|
  spec.name        = 'omen'
  spec.version     = Omen::VERSION
  spec.authors     = [ 'Claudio Baccigalupo' ]
  spec.email       = [ 'claudiob@users.noreply.github.com' ]
  spec.homepage    = 'https://github.com/claudiob/omen'
  spec.summary     = 'Ask Claude about your own data'
  spec.description = 'Turns a question into the SQL that answers it, and runs it read-only'
  spec.license     = 'MIT'

  spec.metadata['homepage_uri']    = spec.homepage
  spec.metadata['source_code_uri'] = 'https://github.com/claudiob/omen/'
  spec.metadata['changelog_uri']   = 'https://github.com/claudiob/omen/blob/main/CHANGELOG.md'
  spec.required_ruby_version       = '>= 3'

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    Dir['{app,config,db,lib}/**/*', 'MIT-LICENSE', 'Rakefile', 'README.md']
  end

  spec.add_dependency 'rails' # to autoload the models and prefix their tables
end
