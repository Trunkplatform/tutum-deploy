require 'logger'
require 'tutum'
require_relative "../../../tutum/tutum_api"
require 'rufus-scheduler'
require 'colored'

module Trunk
  module TutumDeploy
    class Connection

      attr_reader :session

      def initialize
        raise 'Failure: Make sure you specified TUTUM_USERNAME and TUTUM_API_KEY'.red if ENV["TUTUM_USERNAME"].nil? || ENV["TUTUM_API_KEY"].nil?

        @session = Tutum.new(:username => "#{ENV['TUTUM_USERNAME']}", :api_key => "#{ENV['TUTUM_API_KEY']}")
        @logger = Logger.new(STDOUT)
        @logger.progname = "Tutum Deploy"
      end

      def get_services(service_name)
        @session.services.list({:name => service_name})[:objects]
      end

      def get_service(service_name)
        services = get_services(service_name)
        raise "Failure: Multiple services with name: #{service_name}" if services.length > 1
        services[0]
      end

      def decide_bluegreen(service_name)
        services = get_services(service_name)

        bluegreen = {}
        services.each { |service|
          if service[:state] == "Stopped"
            bluegreen[:to_deploy] = service
          else
            bluegreen[:to_shutdown]  = service
          end
        }
        bluegreen
      end

      def deploy(service, version)
        deploy_image = service[:image_name].gsub(/:(.*)/, ":#{version}")

        @session.services.update(service[:uuid], :image_name => deploy_image)
        @session.services.start(service[:uuid])
      end

      def wait_for_healthy(service, ping_uri, sleep_interval, max_timeout, &block)
        (sleep_interval..max_timeout).step(sleep_interval) do
          if ping_service(service, ping_uri)
            return yield @session.services.get(service[:uuid])
          else
            @logger.info("waiting for service to start, sleeping for #{sleep_interval}")
          end
        end

        error_msg = "service #{service[:uuid]} not started after maximum time out of #{max_timeout} seconds"
        @logger.error(error_msg)
        abort(error_msg)
      end

      def ping_service (service, ping_uri)
        ping_url "#{service[:public_dns]}/#{ping_uri}"
      end

      def ping_url(ping_url)
        response = RestClient.get ping_url
        response.code == 200
      end

      def router_switch(router_name, deployed_service)
        deployed_name = deployed_service[:name]
        abort("deployed service #{deployed_name} is currently stopped") if deployed_service[:state] == "Stopped"

        router_service = get_service(router_name)
        linked_services = router_service[:linked_to_service]

        deployed_uri = deployed_service[:resource_uri]
        linked_services.each {|linked_service|
          linked_service[:to_service] = deployed_uri if linked_service[:name] == deployed_name
        }

        @session.services.update(router_service[:uuid], :linked_to_service => linked_services)
      end
    end
  end
end