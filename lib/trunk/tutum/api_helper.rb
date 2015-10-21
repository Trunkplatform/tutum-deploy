require 'logger'
require 'tutum'
require 'rest-client'
require 'tutum/tutum_api'
# require_relative "../../../tutum/tutum_api"

module Trunk::Tutum::ApiHelper

  def services(service_name)
    services = @tutum_api.services.list({:name => service_name})[:objects]
    raise "Failure: No services found for: #{service_name}" if services.length == 0
    services
  end

  def service(service_name)
    services = services(service_name)
    raise "Failure: Multiple services with name: #{service_name}" if services.length > 1
    @tutum_api.services.get(services[0][:uuid])
  end

  def ping_url(service, ping_path)
    "#{service[:public_dns]}/#{ping_path}"
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

  def completed?(action_uri, &block)
    action_uuid = action_uri.match(/\/action\/(.*)\//i).captures[0]

    (0..@max_timeout).step(@sleep_interval) do
      status = @tutum_api.actions.get(action_uuid)[:state]
      if status == 'Success' || status == 'Failed'
        @logger.info("Action #{status}")
        return block.call status
      end
      @logger.debug("action #{status}, sleeping for #{@sleep_interval}")
      sleep @sleep_interval
    end

    error_msg = "Action not completed after maximum time out of #{@max_timeout} seconds"
    @logger.error(error_msg)
    abort(error_msg)
  end

  def healthy?(ping_url, &block)
    (0..@max_timeout).step(@sleep_interval) do
      return block.call true if ping ping_url
      @logger.debug("sleeping for #{@sleep_interval}")
      sleep @sleep_interval
    end

    error_msg = "service not healthy after maximum time out of #{@max_timeout} seconds"
    @logger.error(error_msg)
    abort(error_msg)
  end

end
