require 'logger'
require 'tutum'
require 'trunk/tutum/api_helper'
# require "../../../tutum/tutum_api"
require 'tutum/tutum_api'
require 'colored'

module Trunk
  module Tutum
    module Deploy
      class Deployment
        include Trunk::Tutum::ApiHelper

        attr_reader :tutum_api

        def initialize(session, sleep_interval = 5, max_timeout = 60)
          @tutum_api = session
          @sleep_interval = sleep_interval
          @max_timeout = max_timeout

          @logger = Logger.new(STDOUT)
          @logger.progname = "Tutum Deploy"
        end

        def decide_bluegreen(service_name)
          services = get_services(service_name)

          bluegreen = {}
          services.each { |service|
            if service[:state] == "Stopped"
              bluegreen[:to_deploy] = service
            else
              bluegreen[:to_shutdown] = service
            end
          }
          bluegreen
        end

        def deploy(service, version)
          deploy_image = service[:image_name].gsub(/:(.*)/, ":#{version}")

          @logger.info "updating #{service[:name]} image to #{deploy_image}"
          @tutum_api.services.update(service[:uuid], :image_name => deploy_image)

          @logger.info "starting #{service[:name]} with uuid #{service[:uuid]}"
          @tutum_api.services.start(service[:uuid])
        end

        def healthy_deploy(service, version)
          deploy_image = service[:image_name].gsub(/:(.*)/, ":#{version}")

          @tutum_api.services.update(service[:uuid], :image_name => deploy_image)
          @tutum_api.services.start(service[:uuid])
        end


        def wait_for_healthy(service, ping_uri, &block)
          (0..@max_timeout).step(@sleep_interval) do
            if ping_service(service, ping_uri)
              return yield @tutum_api.services.get(service[:uuid])
            else
              @logger.info("waiting for service to start, sleeping for #{@sleep_interval}")
              sleep @sleep_interval
            end
          end

          error_msg = "service #{service[:uuid]} not started after maximum time out of #{@max_timeout} seconds"
          @logger.error(error_msg)
          abort(error_msg)
        end

        def router_switch(router_name, deployed_service)
          deployed_name = deployed_service[:name]
          abort("deployed service #{deployed_name} is currently stopped") if deployed_service[:state] == "Stopped"

          router_service = get_service(router_name)
          linked_services = router_service[:linked_to_service]

          deployed_uri = deployed_service[:resource_uri]
          linked_services.each { |linked_service|
            linked_service[:to_service] = deployed_uri if linked_service[:name] == deployed_name
          }

          @tutum_api.services.update(router_service[:uuid], :linked_to_service => linked_services)
        end
      end
    end
  end
end