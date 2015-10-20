require 'trunk/tutum/deploy'
require 'logger'
require 'colored'

namespace :tutum do

  raise 'Failure: Make sure you specified TUTUM_USERNAME and TUTUM_API_KEY'.red if ENV["TUTUM_USERNAME"].nil? || ENV["TUTUM_API_KEY"].nil?
  @tutum_api = Tutum.new(:username => "#{ENV['TUTUM_USERNAME']}", :api_key => "#{ENV['TUTUM_API_KEY']}")


  # sleep_interval =  if ENV['SLEEP_INTERVAL'].nil?
  # max_timeout =  ENV['MAX_TIMEOUT'].nil?

  @deployment = Trunk::Tutum::Deploy::Deployment.new(@tutum_api)
  @logger = Logger.new(STDOUT)
  @logger.progname = 'Tutum Deployment'

  desc 'Deploy Service with zero downtime'
  task :deploy, [:service_name, :version] do |_, args|
    begin
      to_deploy = @deployment.service(args[:service_name])

      @logger.info("deploying: #{to_deploy[:public_dns]} with version #{args[:version]}")
      @deployment.deploy(to_deploy, args[:version])

      @deployment.wait_for_healthy(to_deploy) {|deployed|
        @logger.info("#{deployed[:public_dns]} running healthy")
      }
    rescue Exception => ex
      @logger.error ex.backtrace
      abort ex.message.red
    end
  end

  desc 'Deploy Service with zero downtime'
  task :zero_deploy, [:service_name, :version, :router_name, :ping_uri] do |_, args|
    service_name = args[:service_name]
    version = args[:version]
    router_name = args[:router_name]
    ping_uri = args[:ping_uri]

    begin
      bluegreen_services = @deployment.decide_bluegreen(service_name)
      to_deploy = bluegreen_services[:to_deploy]
      to_shutdown = bluegreen_services[:to_shutdown]

      @logger.info("deploying: #{to_deploy} with version #{version}")
      @deployment.deploy(to_deploy, version)

      @logger.info("waiting for: #{to_deploy} to startup")
      @deployment.wait_for_healthy(to_deploy, ping_uri) { |deployed|
        @logger.info("switching router #{router_name}")
        @deployment.router_switch(router_name, deployed) {
          @tutum_api.services.stop(to_shutdown[:uuid])
        }
      }
    rescue Exception => ex
      @logger.error ex.backtrace
      abort ex.message.red
    end
  end

  desc 'Service level Health Check'
  task :ping_service, [:ping_url] do |_, args|
    begin
      @deployment.ping(args[:ping_url])
    rescue Exception => ex
      @logger.error ex.backtrace
      abort ex.message.red
    end
  end

end