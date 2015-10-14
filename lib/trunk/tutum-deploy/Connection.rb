require 'logger'
require 'tutum'
require_relative "../../tutum_api"
require 'rufus-scheduler'


module Trunk
  module TutumDeploy
    class Connection

      attr_reader :session

      def initialize
        raise 'Failure: Make sure you specified TUTUM_USERNAME and TUTUM_API_KEY'.red if ENV["TUTUM_USERNAME"].nil? || ENV["TUTUM_API_KEY"].nil?

        @session = Tutum.new(:username => "#{ENV['TUTUM_USERNAME']}", :api_key => "#{ENV['TUTUM_API_KEY']}")
        @logger = Logger.new(STDOUT)
        @logger.progname = "Tutum"
      end

      def services(service_name)
        @services = @session.services.list({:name => service_name})[:objects]
      end

      def service(service_name)
        services = services(service_name)
        raise "Failure: Multiple services with name: #{service_name}" if services.length > 1
        services[0]
      end

      def decide_bluegreen(service_name)
        services = services(service_name)

        services.each { |service|
          if service[:state] == "Stopped"
            @to_deploy = service
          else
            @to_shutdown = service
          end
        }
        {:to_deploy => @to_deploy, :to_shutdown => @to_shutdown}
      end

      def deploy(service, version)
        deploy_image = service[:image_name].gsub(/:(.*)/, ":#{version}")

        @session.services.update(service[:uuid], :image_name => deploy_image)
        @session.services.start(service[:uuid])
      end

      def wait_for_healthy(service_uuid, ping_url, sleep_interval, max_timeout)
        (sleep_interval..max_timeout).step(sleep_interval) do
          if check_heath ping_url
            return
          else
            @logger.info("waiting for service to start, sleeping for #{sleep_interval}")
          end
        end
        @logger.error("service #{service_uuid} not started after maximum time out of #{max_timeout}")
        abort("service #{service_uuid} not started after maximum time out of #{max_timeout}")
      end

      def check_heath(ping_url)
        response = RestClient.get ping_url
        response.code == 200
      end

    end
  end
end