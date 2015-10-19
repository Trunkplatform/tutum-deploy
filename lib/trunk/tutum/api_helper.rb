require 'logger'
require 'tutum'
require 'rest-client'
require 'tutum/tutum_api'
# require_relative "../../../tutum/tutum_api"

module Trunk
  module Tutum
    module ApiHelper

      def get_services(service_name)
        @tutum_api.services.list({:name => service_name})[:objects]
      end

      def get_service(service_name)
        services = get_services(service_name)
        raise "Failure: Multiple services with name: #{service_name}" if services.length > 1
        services[0]
      end

      def ping_service (service, ping_uri)
        ping_url "#{service[:public_dns]}/#{ping_uri}"
      end

      def ping_url(ping_url)
        begin
          response = RestClient.get ping_url
          response.code == 200
        rescue Exception => ex
          @logger.warn("ping #{ping_url} failed with #{ex}")
          return false
        end

      end
    end
  end
end