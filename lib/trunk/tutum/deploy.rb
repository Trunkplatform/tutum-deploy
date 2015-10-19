require 'trunk/tutum/deploy/deployment'
require 'trunk/tutum/helpers/api_helper'
require 'trunk/tutum/deploy/version'

module Trunk
  module Tutum
    module Deploy
      raise 'Failure: Make sure you specified TUTUM_USERNAME and TUTUM_API_KEY'.red if ENV["TUTUM_USERNAME"].nil? || ENV["TUTUM_API_KEY"].nil?
      @tutum_api = Tutum.new(:username => "#{ENV['TUTUM_USERNAME']}", :api_key => "#{ENV['TUTUM_API_KEY']}")
      @deployment = Trunk::Tutum::Deploy::Deployment.new(@tutum_api)

      @logger = Logger.new(STDOUT)
      @logger.progname = 'Tutum Deployment'

      def self.deploy (service_name, version)
        @deployment.deploy(service_name, version)
      end

      def self.zero_deploy (service_name, version, router_name, ping_uri)
        bluegreen_services = @deployment.decide_bluegreen(service_name)
        to_deploy = bluegreen_services[:to_deploy]

        @logger.info("deploying: #{to_deploy} with version #{version}")
        @deployment.deploy(to_deploy, version)

        @logger.info("waiting for: #{to_deploy} to startup")
        @deployment.wait_for_healthy(to_deploy, ping_uri) { |deployed|
          @logger.info("switching router #{router_name}")
          @deployment.router_switch(router_name, deployed)
        }
      end

      def self.service? (service_name, stack_name, uri)
        ping_url = "http://#{service_name}.#{stack_name}/#{uri}"
        @deployment.ping(ping_url)
      end
    end
  end
end
