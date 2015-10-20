require 'logger'
require 'tutum'
require 'trunk/tutum/api_helper'
# require "../../../tutum/tutum_api"
require 'tutum/tutum_api'
require 'colored'

module Trunk::Tutum::Deploy
  class Deployment
    include Trunk::Tutum::ApiHelper

    attr_reader :tutum_api

    def initialize(tutum_api, sleep_interval = 5, max_timeout = 60)
      @tutum_api = tutum_api
      @sleep_interval = sleep_interval
      @max_timeout = max_timeout

      @logger = Logger.new(STDOUT)
      @logger.progname = "Tutum Deployment"
    end

    def get_candidates(service_name)
      candidates = {}
      services(service_name).each { |service|
        if service[:state] == "Stopped"
          candidates[:to_deploy] = service
        else
          candidates[:to_shutdown] = service
        end
      }
      candidates
    end

    def deploy(service, version)
      deploy_image = service[:image_name].gsub(/:(.*)/, ":#{version}")

      @logger.info "updating [#{service[:public_dns]}] to image [#{deploy_image}]"
      @tutum_api.services.update(service[:uuid], :image => deploy_image)

      @logger.info "redeploying [#{service[:public_dns]}]"
      @tutum_api.services.redeploy(service[:uuid])
    end

    def router_switch(router_name, deployed_service)
      deployed_name = deployed_service[:name]
      abort("deployed service #{deployed_name} is currently stopped") if deployed_service[:state] == "Stopped"

      router_service = service(router_name)
      linked_services = router_service[:linked_to_service]

      deployed_uri = deployed_service[:resource_uri]
      linked_services.each { |linked_service|
        linked_service[:to_service] = deployed_uri if linked_service[:name] == deployed_name
      }

      @tutum_api.services.update(router_service[:uuid], :linked_to_service => linked_services)
    end
  end
end
