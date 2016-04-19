require 'logger'
require 'colored'

namespace :tutum do

  def load_tutum
    STDOUT.sync = true
    @logger = Logger.new(STDOUT)
    @logger.progname = 'Tutum Deployment'
    require 'trunk/tutum_api/deploy'
    include Trunk::TutumApi::Deploy
  end


  def sleep_interval
    @sleep_interval = ENV['SLEEP_INTERVAL'] || 5
    @sleep_interval.to_i
  end

  def max_timeout
    @max_timeout = ENV['MAX_TIMEOUT'] || 600
    @max_timeout.to_i
  end

  def tutum_proxy_path
    @proxy_path = ENV['PROXY_PATH']
  end

  def tutum_api
    raise 'Failure: Make sure you specified TUTUM_USER and TUTUM_APIKEY'.red if ENV["TUTUM_USER"].nil? || ENV["TUTUM_APIKEY"].nil?
    @tutum_api ||= Tutum.new(:username => "#{ENV['TUTUM_USER']}", :api_key => "#{ENV['TUTUM_APIKEY']}")
  end

  desc 'Deploy Single Stack Service'
  task :single_stack_deploy, [:service_name, :version, :ping_uri, :ping_port] do |_, args|
    load_tutum

    service_name = args[:service_name]
    version = args[:version]
    ping_path = ":#{args[:ping_port] || '80'}/#{args[:ping_uri] || 'ping'}"

    begin
      @deployment = Deployment.new(tutum_api, service_name, version, ping_path, sleep_interval, max_timeout, tutum_proxy_path)
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
    load_tutum

    service_name = args[:service_name]
    version = args[:version]
    router_name = args[:router_name]
    ping_path = ":#{args[:ping_port] || '80'}/#{args[:ping_uri] || 'ping'}"

    begin
      @deployment = Trunk::TutumApi::Deploy::Deployment
                        .new(tutum_api, service_name, version, ping_path, sleep_interval, max_timeout, tutum_proxy_path)
                        .get_candidates(router_name).dual_stack_deploy router_name
    rescue Exception => ex
      @logger.error ex.backtrace
      abort ex.message.red
    end
  end

  desc 'Service level Health Check'
  task :ping_service, [:ping_url] do |_, args|
    load_tutum

    begin
      @deployment.ping(args[:ping_url])
    rescue Exception => ex
      @logger.error ex.backtrace
      abort ex.message.red
    end
  end

  desc 'Service router relink'
  task :relink_router, [:router_name, :service_uuid] do |_, args|
    load_tutum
    router_name = args[:router_name]
    service_uuid = args[:service_uuid]

    begin
      @deployment = Deployment.new(tutum_api, nil, nil)
      service_to_switch = @deployment.tutum_api.services.get(service_uuid)
      @deployment.router_switch(router_name, service_to_switch) {|router_service|
        @logger.info("#{router_name} to links: #{router_service[:linked_to_service]}")
      }
    rescue Exception => ex
      @logger.error ex.backtace
      abort ex.message.red
    end

  end

end