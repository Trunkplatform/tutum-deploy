require 'trunk/tutum/deploy'
require 'logger'
require 'colored'

namespace :tutum do
  @logger = Logger.new(STDOUT)
  @logger.progname = 'Deploy Task'

  desc 'Deploy Service with zero downtime'
  task :deploy, [:service_name, :version] do |_, args|
    begin
      Trunk::Tutum::Deploy.deploy(args[:service_name], args[:version])
    rescue Exception => ex
      @logger.error ex.backtrace
      abort ex.message.red
    end
  end

  desc 'Deploy Service with zero downtime'
  task :deploy, [:service_name, :version, :router_name, :ping_uri] do |_, args|
    begin
      Trunk::Tutum::Deploy.zero_deploy(args[:service_name], args[:version], args[:router_name], args[:ping_uri])
    rescue Exception => ex
      @logger.error ex.backtrace
      abort ex.message.red
    end
  end

  desc 'Service level Health Check'
  task :ping_service, [:service_name, :stack_name, :uri] do |_, args|
    begin
      Trunk::Tutum::Deploy.service?(args[:service_name], args[:stack_name], args[:version])
    rescue Exception => ex
      @logger.error ex.backtrace
      abort ex.message.red
    end
  end

end