require 'trunk/tutum/deploy'
require 'logger'
require 'colored'

namespace :tutum do
  @logger = Logger.new(STDOUT)
  @logger.progname = 'Deployer'

  desc 'Deploy Service with zero downtime'
  task :deploy, [:service_name, :version] do |_, args|
    begin
      Trunk::TutumDeploy.deploy(args[:service_name], args[:version])
    rescue Exception => ex
      @logger.error ex.backtrace
      abort ex.message.red
    end
  end

  desc 'Service level Health Check'
  task :ping_service, [:service_name, :version] do |_, args|
    begin
      Trunk::TutumDeploy.(args[:service_name], args[:version])
    rescue Exception => ex
      @logger.error ex.backtrace
      abort ex.message.red
    end
  end

  desc 'Service level Health Check'
  task :ping_service, [:service_name, :stack] do |_, args|
    begin
      Trunk::TutumDeploy.(args[:service_name], args[:version])
    rescue Exception => ex
      @logger.error ex.backtrace
      abort ex.message.red
    end
  end

end