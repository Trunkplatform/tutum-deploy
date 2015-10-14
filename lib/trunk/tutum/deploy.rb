require 'trunk/tutum/deploy/connection'
require 'trunk/tutum/deploy/version'

module Trunk
  module TutumDeploy
    @connection = Trunk::TutumDeploy::Connection::new

    def deploy (service_name, version)
      @connection.deploy(service_name, version)
    end

    def zero_deploy (router, service_name)
      blue_green = connection.decide_bluegreen(service_name)
    end
  end
end
