# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'trunk/tutum-deploy/version'

Gem::Specification.new do |spec|
  spec.name          = "tutum-deploy"
  spec.version       = Trunk::TutumDeploy::VERSION
  spec.authors       = ["Yun Zhi Lin"]
  spec.email         = ["yun@yunspace.com"]
  spec.summary       = "A gem for doing zero downtime deployments in Tutum"
  spec.description   = "A gem for doing zero downtime deployments in Tutum"
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.6"
  spec.add_development_dependency "rake"
  spec.add_development_dependency('webmock', '~> 1.21')
  spec.add_development_dependency('rspec', '~> 3.3')
  spec.add_development_dependency('pry', '~> 0.9')
  spec.add_development_dependency('awesome_print', '~> 1.6')

  spec.add_dependency('rufus-scheduler', '~> 3.1')
  spec.add_dependency('tutum', '~> 0.2')
end
