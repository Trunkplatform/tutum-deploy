require 'logger'
require 'tutum'
require 'trunk/tutum_api/api_helper'
require 'colored'

module Trunk
  module TutumApi
    module Deploy
      class Deployment
        include Trunk::TutumApi::ApiHelper

        attr_reader :tutum_api, :service_name, :ping_path, :proxy_path
        attr_accessor :to_deploy, :to_shutdown

        def initialize(tutum_api, service_name, version, ping_path='/', sleep_interval = 5, max_timeout = 60, overlay_proxy='')
          @tutum_api = tutum_api
          @service_name = service_name
          @version = version
          @ping_path = ping_path

          @sleep_interval = sleep_interval
          @max_timeout = max_timeout

          @proxy_path = overlay_proxy

          @logger = Logger.new(STDOUT)
          @logger.progname = "Tutum Deployment"
        end

        def get_candidates()
          services = services(@service_name)

          if services.length == 1
            @to_deploy ||= services[0]
          else
            services.each { |service|
              service_state = service[:state]
              if service_state == "Stopped" || service_state == 'Not running'
                @to_deploy ||= service
              elsif service_state == "Running"
                @to_shutdown ||= service
              end
            }
          end
          @logger.debug ("to_deploy: #{@to_deploy[:public_dns]}") if @to_deploy
          @logger.debug ("to_shutdown: #{@to_shutdown[:public_dns]}") if @to_shutdown

          self
        end

        def single_stack_deploy (&block)
          @logger.info("deploying: #{@to_deploy[:public_dns]} with version #{@version}")
          response = deploy
          completed?(response[:action_uri]) { |action_state|
            @logger.info "Deployment status: #{action_state})"
            if action_state == "Success"
              healthy? (ping_url(@to_deploy, @ping_path, @proxy_path)) {
                @logger.info "#{@to_deploy[:public_dns]} running healthy"
                block.call @tutum_api.services.get(@to_deploy[:uuid])
              }
            else
              raise("deployment failed")
            end
          }
        end

        def dual_stack_deploy(router_name)
          raise "nothing to deploy" if @to_deploy.nil?

          single_stack_deploy { |deployed|
            router_switch(router_name, deployed) {
              @logger.info("router switched #{deployed[:public_dns]}, shutting down #{to_shutdown[:public_dns]}")
              if @to_shutdown
                response = @tutum_api.services.stop(@to_shutdown[:uuid])
                completed? (response[:action_uri]) { |action_state|
                  if action_state == "Failed"
                    raise "failed to stop Service"
                  end
                }
              end
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

        def router_switch(router_name, deployed, &block)
          deployed_name = deployed[:name]
          raise("deployed service #{deployed_name} is not running") if deployed[:state] != "Running"

          router_service = service(router_name)
          linked_services = router_service[:linked_to_service]

          deployed_uri = deployed[:resource_uri]
          linked_services.each { |linked_service|
            linked_service[:to_service] = deployed_uri if linked_service[:name] == deployed_name
          }

          @logger.info("switching router #{router_name} to use #{deployed[:public_dns]}")
          response = @tutum_api.services.update(router_service[:uuid], :linked_to_service => linked_services)
          completed?(response[:action_uri]) { |action_state|
            if action_state == "Success"
              return block.call
            else
              raise("failed to switch router")
            end
          }
        end
      end
    end
  end
end
