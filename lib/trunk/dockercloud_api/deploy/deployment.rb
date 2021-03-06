require 'logger'
require 'tutum'
require 'trunk/dockercloud_api/api_helper'
require 'colored'
require 'rest-client'

module Trunk
  module DockercloudApi
    module Deploy
      class Deployment
        include Trunk::DockercloudApi::ApiHelper

        attr_reader :tutum_api, :service_name, :ping_path, :proxy_path
        attr_accessor :to_deploy, :to_shutdown

        def parse_service_alias(linked_service_name)
          tokens = linked_service_name.split('-')
          return tokens.pop, tokens.join('-')
        end

        def initialize(tutum_api, service_name, version, ping_path='/', sleep_interval = 5, max_timeout = 60, overlay_proxy=nil)
          @tutum_api = tutum_api
          @service_name = service_name
          @version = version
          @ping_path = ping_path

          @sleep_interval = sleep_interval
          @max_timeout = max_timeout

          @proxy_path = overlay_proxy

          STDOUT.sync = true
          @logger = Logger.new(STDOUT)
          @logger.progname = "Tutum Deployment"

          @logger.info "new deployment for #{service_name}:#{version}, time out #{@sleep_interval}/#{@max_timeout}"
          @logger.info "ping_path at #{ping_path} using proxy: #{overlay_proxy}"
        end

        def get_candidates(router_name = nil)
          services = services(@service_name)

          if services.length == 1
            @to_deploy ||= services[0]
          else
            # get linked services of router
            router_service = service(router_name)
            linked_services = router_service[:linked_to_service]

            # loop through services to find one that the router points to
            linked_services.each { |linked_service|
              if linked_service[:name] == @service_name
                services.each { |service|
                  if linked_service[:to_service].include? service[:uuid]
                    @to_shutdown = service
                  else
                    @to_deploy = service
                  end
                }
                break
              end
            }
          end
          @logger.debug ("to_deploy: #{@to_deploy ? @to_deploy[:public_dns] : 'nothing'}")
          @logger.debug ("to_shutdown: #{@to_shutdown ? @to_shutdown[:public_dns] : 'nothing'}")

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
            router_switch(router_name, deployed) {|router_service|

              # router_reload(router_service)

              @logger.info("router switched #{deployed[:public_dns]}, shutting down #{to_shutdown[:public_dns]}")
              if @to_shutdown
                response = @tutum_api.services.stop(@to_shutdown[:uuid])
                if response[:action_uri].nil?
                  @logger.warn("Response from tutum was: #{response.inspect}")
                end
                completed? (response[:action_uri]) { |action_state|
                  if action_state == "Failed"
                    raise "failed to stop Service"
                  end
                }
              end
            }
          }
        end

        def deploy
          deploy_image = @to_deploy[:image_name].gsub(/:(.*)/, ":#{@version}")

          @logger.info "updating [#{@to_deploy[:public_dns]}] to image [#{deploy_image}]"
          @tutum_api.services.update(@to_deploy[:uuid], :image => deploy_image)

          @logger.info "redeploying [#{@to_deploy[:public_dns]}]"
          @tutum_api.services.redeploy(@to_deploy[:uuid])
        end

        def router_reload(router_service)
          @logger.info("sleeping for #{@sleep_interval} and then reloading HAProxy")
          sleep @sleep_interval
          reload_url = "http://#{router_service[:public_dns]}:5000/main/reload"

          begin
            response = RestClient.get(reload_url)
            if response.code == 200
              @logger.info("HAProxy API response: " + response.body)
            else
              @logger.warn("Failed HAProxy reload via API, error code: #{response.code}")
            end
            return response
          rescue Exception => ex
            @logger.error ex.backtrace
          end
        end

        def router_switch(router_name, deployed, &block)
          deployed_name = deployed[:name]
          raise("deployed service #{deployed_name} is not running") if deployed[:state] != "Running"

          router_service = service(router_name)
          linked_services = router_service[:linked_to_service]

          deployed_uri = deployed[:resource_uri]

          linked_services.each do |linked_service|
            if linked_service[:name] == deployed_name
              linked_service[:to_service] = deployed_uri
            end
          end

          @logger.info("switching router #{router_name} to use #{deployed[:public_dns]}")
          response = @tutum_api.services.update(router_service[:uuid], :linked_to_service => linked_services)
          if response[:action_uri]
            completed?(response[:action_uri]) { |action_state|
              if action_state == "Success"
                return block.call router_service
              else
                raise("failed to switch router")
              end
            }
          else
            healthy? (ping_url(@to_deploy, @ping_path, @proxy_path)) {
              @logger.info "#{@to_deploy[:public_dns]} running healthy"
              block.call @tutum_api.services.get(@to_deploy[:uuid])
            }
          end

        end
      end
    end
  end
end
