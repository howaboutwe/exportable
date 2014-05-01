$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "exportable/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "exportable"
  s.version     = Exportable::VERSION
  s.authors     = ["Andrew Watkins", 'Dave Brown', 'Kenneth Lay']
  s.email       = ["dev@howaboutwe.com"]
  s.homepage    = "https://github.com/howaboutwe/exportable"
  s.summary     = "Allows the exportation of random stuff."
  s.description = "Exports stuff"
  s.license     = "MIT"

  s.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.rdoc"]
  s.test_files = Dir["spec/**/*"]

  s.add_dependency "rails", "< 5.0"

  s.add_dependency "mysql2"
end
