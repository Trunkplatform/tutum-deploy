require 'trunk/tutum/deploy/deployment'
require 'trunk/tutum/api_helper'
require 'trunk/tutum/deploy/version'

module Trunk::Tutum::Deploy

  def sync_deploy (to_deploy, version, ping_uri = "/", &block)
    @logger.info("deploying: #{to_deploy[:public_dns]} with version #{version}")
    response = @deployment.deploy(to_deploy, version)

    @deployment.completed?(response[:action_uri]) { |completed_action|
      action_state = completed_action[:state]
      @logger.info("deployment status: #{completed_action[:state]}")

      if action_state == "Success"
        @deployment.healthy?(to_deploy, ping_uri) { |healthy_service|
          @logger.info("#{healthy_service[:public_dns]} running healthy")
          block.call healthy_service
        }
      elsif
        @logger.error("deployment failed")
        abort("deployment failed")
      end
    }
  end

  def zero_deploy(service_name, version, router_name, ping_uri)
    bluegreen_services = @deployment.get_candidates(service_name)
    to_deploy = bluegreen_services[:to_deploy]
    to_shutdown = bluegreen_services[:to_shutdown]

    @logger.info("deploying: #{to_deploy} with version #{version}")
    sync_deploy(to_deploy, ping_uri, version) { |deployed|
      @logger.info("switching router #{router_name}")
      @deployment.router_switch(router_name, deployed) {
        @tutum_api.services.stop(to_shutdown[:uuid])
      }
    }
  end

end