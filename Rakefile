spec = Gem::Specification.find_by_name 'tutum-deploy'
Dir.glob("#{spec.gem_dir}/lib/tasks/*.rake").each {|r| import r }


begin
  require 'rspec/core/rake_task'
  RSpec::Core::RakeTask.new(:spec)
rescue LoadError
end

task default: :spec