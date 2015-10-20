require 'json'
require 'trunk/tutum/api_helper'

module TestFixtures

  TUTUM_API_URL = "https://dashboard.tutum.co/api/v1"
  TUTUM_API = Tutum.new(:username => "tutum_alice", :api_key => "DEADBEEFKEY")

  SERVICE_RUNNING = {
      :uuid => "blue-uuid",
      :image_name => "trunk/web-sandbox:v1",
      :name => "web-sandbox",
      :resource_uri => "/api/v1/service/blue-uuid/",
      :stack => "/api/v1/stack/blue-stack/",
      :state => "Running",
      :public_dns => "web-sandbox.blue-stack.trunkbot.svc.tutum.io"
  }
  SERVICE_STOPPED = {
      :uuid => "green-uuid",
      :image_name => "trunk/web-sandbox:v1",
      :name => "web-sandbox",
      :resource_uri => "/api/v1/service/green-uuid/",
      :stack => "/api/v1/stack/green-stack/",
      :state => "Stopped",
      :public_dns => "web-sandbox.green-stack.trunkbot.svc.tutum.io"
  }
  SERVICES_RESPONSE_HASH = {
      :meta => {},
      :objects => [SERVICE_RUNNING, SERVICE_STOPPED]
  }
  SERVICES_RESPONSE_JSON = JSON.generate(SERVICES_RESPONSE_HASH)

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
              :to_service => "/api/v1/service/green-uuid/"
          },
          {
              :from_service => "/api/v1/service/router-uuid/",
              :name => "irrelevant",
              :to_service => "/api/v1/service/irrelevant_linked_service/"
          }
      ],
  }
  ROUTER_RESPONSE_HASH = {
      :meta => {},
      :objects => [ROUTER]
  }
  ROUTER_RESPONSE_JSON = JSON.generate(ROUTER_RESPONSE_HASH)

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
    include Trunk::Tutum::ApiHelper

    attr_reader :tutum_api
    def initialize(session, sleep_interval = 5, max_timeout = 60)
      @tutum_api = session
      @sleep_interval = sleep_interval
      @max_timeout = max_timeout
      @logger = Logger.new(STDOUT)
      @logger.progname = 'Test'
    end
  end
end