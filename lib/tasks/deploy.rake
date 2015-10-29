require 'trunk/tutum_api/deploy'
require 'logger'
require 'colored'

include Trunk::TutumApi::Deploy

namespace :tutum do

  @logger = Logger.new(STDOUT)
  @logger.progname = 'Tutum Deployment'

  def sleep_interval
    @sleep_interval = ENV['SLEEP_INTERVAL'] || 5
    @sleep_interval.to_i
  end

  def max_timeout
    @max_timeout = ENV['MAX_TIMEOUT'] || 120
    @max_timeout.to_i
  end

  def proxy_path
    @proxy_path = ENV['PROXY_PATH'] || 'wtf'
  end

  def tutum_api
    raise 'Failure: Make sure you specified TUTUM_USERNAME and TUTUM_API_KEY'.red if ENV["TUTUM_USERNAME"].nil? || ENV["TUTUM_API_KEY"].nil?
    @tutum_api ||= Tutum.new(:username => "#{ENV['TUTUM_USERNAME']}", :api_key => "#{ENV['TUTUM_API_KEY']}")
  end

  desc 'Deploy Single Stack Service'
  task :single_stack_deploy, [:service_name, :version, :ping_path, :ping_port] do |_, args|
    service_name = args[:service_name]
    version = args[:version]
    ping_path = ":#{args[:ping_port] || '80'}/#{args[:ping_uri] || 'ping'}"

    begin
      @deployment = Deployment.new(tutum_api, service_name, version, ping_path, sleep_interval, max_timeout, proxy_path)
                        .get_candidates.single_stack_deploy {|deployed|
        @logger.info("#{deployed[:public_dns]} deployed successfully")
      }
    rescue Exception => ex
      @logger.error ex.backtrace
      abort ex.message.red
    end
  end

  desc 'Deploy Dual Stack Service with zero downtime'
  task :dual_stack_deploy, [:service_name, :version, :router_name, :ping_uri, :ping_port] do |_, args|
    service_name = args[:service_name]
    version = args[:version]
    router_name = args[:router_name]
    ping_path = ":#{args[:ping_port] || '80'}/#{args[:ping_uri] || 'ping'}"

    begin
      @deployment = Trunk::TutumApi::Deploy::Deployment
                        .new(tutum_api, service_name, version, ping_path, sleep_interval, max_timeout, proxy_path)
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