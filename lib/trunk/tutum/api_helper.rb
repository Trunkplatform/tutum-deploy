require 'logger'
require 'tutum'
require 'rest-client'
require 'tutum/tutum_api'
# require_relative "../../../tutum/tutum_api"

module Trunk
  module Tutum
    module ApiHelper

      def services(service_name)
        services = @tutum_api.services.list({:name => service_name})[:objects]
        raise "Failure: No services found for: #{service_name}" if services.length == 0
        services
      end

      def service(service_name)
        services = services(service_name)
        raise "Failure: Multiple services with name: #{service_name}" if services.length > 1
        services[0]
      end

      def service_healthy?(service, ping_uri)
        ping "#{service[:public_dns]}/#{ping_uri}"
      end

      def ping(ping_url)
        begin
          response = RestClient.get ping_url
          response.code == 200
        rescue Exception => ex
          @logger.warn("ping #{ping_url} failed with #{ex}")
          return false
        end
      end

      # def check_action(service, ping_uri = "/", &block)
      #   service_uuid = service[:uuid]
      #   state = nil
      #   (0..@max_timeout).step(@sleep_interval) do
      #     @tutum_api.actions.list({})
      #     service = @tutum_api.services.get(service_uuid)
      #
      #     if service_healthy?(service, ping_uri)
      #       return yield service
      #     else
      #       @logger.info("waiting for service to redeploy, sleeping for #{@sleep_interval}")
      #       sleep @sleep_interval
      #     end
      #   end
      #
      #   error_msg = "service #{service[:uuid]} not started after maximum time out of #{@max_timeout} seconds"
      #   @logger.error(error_msg)
      #   abort(error_msg)
      # end

    end
  end
end