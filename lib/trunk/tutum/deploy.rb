require 'trunk/tutum/deploy/connection'
require 'trunk/tutum/deploy/version'

module Trunk
  module TutumDeploy
    @connection = Trunk::TutumDeploy::Connection::new

    def deploy (service_name, version)
      @connection.deploy(service_name, version)
    end

    def zero_deploy (router, service_name)
      bluegreen_services = connection.decide_bluegreen(service_name)
    end

    def ping_service (service_name, stack_name, uri)
      ping_url = "http://#{service_name}.#{stack_name}/#{uri}"
      @connection.ping_url(ping_url)
    end
  end
end
