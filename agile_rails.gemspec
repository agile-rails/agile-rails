# Copyright 2024+ Damjan Rems

$:.push File.expand_path('../lib', __FILE__)

# Maintain gem's version:
require 'agile/version'

# Describe gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = 'agile_rails'
  s.version     = Agile::VERSION
  s.authors     = ['Damjan Rems']
  s.email       = ['damjan.rems@gmail.com']
  s.homepage    = 'https://agile-rails.com'
  s.summary     = 'AgileRails: Agile business application development tool and CMS for Ruby on Rails'
  s.description = 'AgileRails, development tool for agile development of in-house (Intranet, business, private cloud) applications as well as CMS for creating complex, data-entry intensive web sites.'
  s.license     = 'MIT'
  s.files       = Dir['{app,config,db,lib}/**/*'] + %w[MIT-LICENSE Rakefile README.md CHANGELOG.md agile_rails.gemspec]
  #s.test_files  = Dir['test/**/*']

  s.metadata['homepage_uri'] = s.homepage
  s.metadata['source_code_uri'] = 'https://github.com/agile-rails/agile-rails'
  s.metadata['changelog_uri'] = 'https://github.com/agile-rails/agile-rails/CHANGELOG.md'

  s.required_ruby_version = '> 3.1'

  s.add_dependency 'jquery-rails'
  s.add_dependency 'jquery-ui-rails'
  s.add_dependency 'non-digest-assets'
  s.add_dependency 'rails'

  s.add_dependency 'bcrypt'
  s.add_dependency 'drg_material_icons'
  s.add_dependency 'kaminari'
  s.add_dependency 'kaminari-actionview'
end
