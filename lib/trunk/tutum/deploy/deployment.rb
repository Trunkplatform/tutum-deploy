require 'logger'
require 'tutum'
require 'trunk/tutum/api_helper'
require 'tutum/tutum_api'
require 'colored'

module Trunk::Tutum::Deploy
  class Deployment
    include Trunk::Tutum::ApiHelper

    attr_reader :tutum_api, :service_name, :ping_path
    attr_accessor :to_deploy, :to_shutdown

    def initialize(tutum_api, service_name, version, ping_path="/", sleep_interval = 5, max_timeout = 60)
      @tutum_api = tutum_api
      @service_name = service_name
      @version = version
      @ping_path = ping_path

      @sleep_interval = sleep_interval
      @max_timeout = max_timeout

      @logger = Logger.new(STDOUT)
      @logger.progname = "Tutum Deployment"
    end

    def get_candidates()
      services = services(@service_name)

      if services.length == 1
        @to_deploy ||= services[0]
      elsif services.each { |service|
        if service[:state] == "Stopped"
          @to_deploy ||= service
        elsif service[:state] == "Running"
          @to_shutdown ||= service
        end
      }
      end
      self
    end

    def single_stack_deploy (&block)
      @logger.info("deploying: #{@to_deploy[:public_dns]} with version #{@version}")
      response = deploy
      completed?(response[:action_uri]) { |action_state|
        @logger.info "Deployment status: #{action_state})"
        if action_state == "Success"
          healthy? (ping_url(@to_deploy, @ping_path)) {
            @logger.info "#{@to_deploy[:public_dns]} running healthy"
            block.call @tutum_api.services.get(@to_deploy[:uuid])
          }
        else
          abort("deployment failed")
        end
      }
    end

    def dual_stack_deploy(router_name)
      single_stack_deploy { |deployed|
        @logger.info("switching router #{router_name} to use #{deployed[:public_dns]}")
        router_switch(router_name, deployed) {
          @tutum_api.services.stop(@to_shutdown[:uuid]) if @to_shutdown
        }
      }
    end

    def dynamic_stack_deploy

    end

    def deploy
      deploy_image = @to_deploy[:image_name].gsub(/:(.*)/, ":#{@version}")

      @logger.info "updating [#{@to_deploy[:public_dns]}] to image [#{deploy_image}]"
      @tutum_api.services.update(@to_deploy[:uuid], :image => deploy_image)

      @logger.info "redeploying [#{@to_deploy[:public_dns]}]"
      @tutum_api.services.redeploy(@to_deploy[:uuid])
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
