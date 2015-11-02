require 'json'
require 'rspec'
require_relative "../../../lib/trunk/tutum_api/api_helper"

module TestFixtures

  TUTUM_API_URL = "https://dashboard.tutum.co/api/v1"
  TUTUM_API = Tutum.new(:username => "tutum_alice", :api_key => "DEADBEEFKEY")

  SERVICE_BLUE = {
      :uuid => "blue-uuid",
      :image_name => "trunk/web-sandbox:v1",
      :name => "web-sandbox",
      :resource_uri => "/api/v1/service/blue-uuid/",
      :stack => "/api/v1/stack/blue-stack/",
      :state => "Running",
      :public_dns => "web-sandbox.blue-stack.trunkbot.svc.tutum.io"
  }
  SERVICE_GREEN = {
      :uuid => "green-uuid",
      :image_name => "trunk/web-sandbox:v1",
      :name => "web-sandbox",
      :resource_uri => "/api/v1/service/green-uuid/",
      :stack => "/api/v1/stack/green-stack/",
      :state => "Stopped",
      :public_dns => "web-sandbox.green-stack.trunkbot.svc.tutum.io"
  }
  SERVICES = {
      :meta => {},
      :objects => [SERVICE_BLUE, SERVICE_GREEN]
  }
  SERVICES_JSON = JSON.generate(SERVICES)

  SERVICE = {
      :meta => {},
      :objects => [SERVICE_BLUE]
  }
  SERVICE_JSON = JSON.generate(SERVICE)

  ROUTER = {
      :uuid => "router-uuid",
      :image_name => "trunk/sandbox-router:v1",
      :name => "web-sandbox",
      :stack => "/api/v1/stack/router-stack/",
      :state => "Running",
      :linked_to_service => [
          {
              :from_service => "/api/v1/service/router-uuid/",
              :name => "web-sandbox",
              :to_service => "/api/v1/service/blue-uuid/"
          },
          {
              :from_service => "/api/v1/service/router-uuid/",
              :name => "irrelevant",
              :to_service => "/api/v1/service/irrelevant_linked_service/"
          }
      ],
  }
  ROUTERS = {
      :meta => {},
      :objects => [ROUTER]
  }
  ROUTERS_JSON = JSON.generate(ROUTERS)

  ACTION_SUCCESS = {
      :action => "Service Update",
      :state => "Success",
      :uuid => "action_success"
  }
  ACTION_FAILED = {
      :action => "Service Update",
      :state => "Failed",
      :uuid => "action_failed"
  }
  ASYNC_RESPONSE = {
      :action_uri => "/api/v1/action/action_success/",
      :body => ACTION_SUCCESS
  }

  class ApiHelperStub
    include Trunk::TutumApi::ApiHelper

    attr_reader :tutum_api
    def initialize(session, service_name="web-sandbox", version="1", ping_path="/", sleep_interval = 1, max_timeout = 2)
      @tutum_api = session
      @service_name = service_name
      @version = version
      @ping_path = ping_path

      @sleep_interval = sleep_interval
      @max_timeout = max_timeout

      @logger = Logger.new(STDOUT)
      @logger.progname = 'Test'
    end
  end
end