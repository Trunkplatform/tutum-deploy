require 'trunk/tutum/deploy'
require 'logger'
require 'colored'

include Trunk::Tutum::Deploy

namespace :tutum do

  raise 'Failure: Make sure you specified TUTUM_USERNAME and TUTUM_API_KEY'.red if ENV["TUTUM_USERNAME"].nil? || ENV["TUTUM_API_KEY"].nil?
  @tutum_api = Tutum.new(:username => "#{ENV['TUTUM_USERNAME']}", :api_key => "#{ENV['TUTUM_API_KEY']}")

  sleep_interval = ENV['SLEEP_INTERVAL']
  sleep_interval ||= 5

  max_timeout =  ENV['MAX_TIMEOUT']
  max_timeout ||= 60

  @logger = Logger.new(STDOUT)
  @logger.progname = 'Tutum Deployment'

  desc 'Deploy Single Stack Service'
  task :single_stack_deploy, [:service_name, :version, :ping_path] do |_, args|

    service_name = args[:service_name]
    version = args[:version]
    ping_path = args[:ping_path]

    begin
      @deployment = Deployment.new(@tutum_api, service_name, version, ping_path, sleep_interval, max_timeout)
                        .get_candidates.single_stack_deploy {|deployed|
        @logger.info("#{deployed[:public_dns]} deployed successfully")
      }
    rescue Exception => ex
      @logger.error ex.backtrace
      abort ex.message.red
    end
  end

  desc 'Deploy Dual Stack Service with zero downtime'
  task :dual_stack_deploy, [:service_name, :version, :router_name, :ping_path] do |_, args|
    service_name = args[:service_name]
    version = args[:version]
    router_name = args[:router_name]
    ping_path = args[:ping_path]

    begin
      @deployment = Trunk::Tutum::Deploy::Deployment
                        .new(@tutum_api, service_name, version, ping_path, sleep_interval, max_timeout)
                        .get_candidates.dual_stack_deploy router_name
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