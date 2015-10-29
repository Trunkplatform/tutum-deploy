# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require_relative 'lib/trunk/tutum_api/deploy/version'

Gem::Specification.new do |s|
  s.name          = "tutum-deploy"
  s.version       = Trunk::TutumApi::Deploy::VERSION
  s.authors       = ["Yun Zhi Lin"]
  s.email         = ["yun@yunspace.com"]
  s.summary       = "A gem for Tutum zero downtime deployments using Stacks"
  s.description   = "A gem for Tutum zero downtime deployments using Stacks"
  s.homepage      = ""
  s.license       = "MIT"

  s.files         = `git ls-files -z`.split("\x0")
  s.executables   = s.files.grep(%r{^bin/}) { |f| File.basename(f) }
  s.test_files    = s.files.grep(%r{^(test|spec|features)/})
  s.require_paths = ["lib"]

  s.add_development_dependency "bundler", "~> 1.6"
  s.add_development_dependency('webmock', '~> 1.21')
  s.add_development_dependency('rspec', '~> 3.3')
  s.add_development_dependency('pry', '~> 0.9')
  s.add_development_dependency('awesome_print', '~> 1.6')

  s.add_dependency('rufus-scheduler', '~> 3.1')
  s.add_dependency('tutum', '~> 0.2')
  s.add_dependency("rake", '~>10.4')
  s.add_dependency('colored', '~> 1.2')
end
