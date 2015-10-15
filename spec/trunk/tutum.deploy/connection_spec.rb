require 'rspec'
require 'webmock/rspec'
require 'json'
require 'trunk/tutum/deploy/connection'

describe Trunk::TutumDeploy::Connection do

  TUTUM_API_URL = "https://dashboard.tutum.co/api/v1"

  subject(:connection) { Trunk::TutumDeploy::Connection.new }

  before :each do
    ENV['TUTUM_USERNAME'] = 'alice'
    ENV['TUTUM_API_KEY'] = 'DEADBEEFKEY'
  end

  describe 'when getting a service' do

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

    it 'should get symbolized hash' do
      # given
      stub_request(:get, "#{TUTUM_API_URL}/service/?name=web-sandbox").to_return(:status => 200, :body => SERVICES_RESPONSE_JSON)

      # when
      services = connection.get_services("web-sandbox")

      # then
      expect(services).to eq(SERVICES_RESPONSE_HASH[:objects])
    end

    it 'should decide blue or green' do
      # given
      stub_request(:get, "#{TUTUM_API_URL}/service/?name=web-sandbox").to_return(:status => 200, :body => SERVICES_RESPONSE_JSON)

      # when
      blue_green = connection.decide_bluegreen("web-sandbox")

      # then
      expect(blue_green[:to_shutdown]).to eq(SERVICES_RESPONSE_HASH[:objects][0])
      expect(blue_green[:to_deploy]).to eq(SERVICES_RESPONSE_HASH[:objects][1])
    end
  end

  describe 'when deploying a service' do

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

    it 'should start with updated image' do
      # given
      service_uuid = SERVICE_STOPPED[:uuid]
      deploy_image = "trunk/web-sandbox:v2"

      stub_request(:get, "#{TUTUM_API_URL}/service/?name=web-sandbox").to_return(:status => 200, :body => SERVICES_RESPONSE_JSON)
      stub_request(:patch, "#{TUTUM_API_URL}/service/#{service_uuid}/")
          .with(:body => "{\"image_name\":\"#{deploy_image}\"}")
          .to_return(:status => 200, :body => "{}")
      stub_request(:post, "#{TUTUM_API_URL}/service/#{service_uuid}/start/").to_return(:status => 200, :body => "{}")

      # when
      connection.deploy(SERVICE_STOPPED, "v2")

      # then
      # expect(connection.session).to receive(update).with(@service_uuid, :image_name => @deploy_image)
      # expect(connection.session).to receive(start).with(@service_uuid)
    end

    it 'should wait for healthy service and run block' do
      # given
      stub_request(:get, "http://#{SERVICE_RUNNING[:public_dns]}/ping").to_return(:status => 200, :body => "{}")
      stub_request(:get, "#{TUTUM_API_URL}/service/#{SERVICE_RUNNING[:uuid]}/")
          .to_return(:status => 200, :body => JSON.generate(SERVICE_RUNNING))

      # when
      connection.wait_for_healthy(SERVICE_RUNNING, "ping", 5, 10) { |healthy|
        # then
        expect(healthy).to eq(SERVICE_RUNNING)
      }
    end

    it 'should timeout after max wait' do
      # when
      begin
        connection.wait_for_healthy(SERVICE_RUNNING, "ping", 5, 1)
      rescue Exception => ex
        # then
        expect(ex.status).to be(1)
      end
    end

    it 'should switch router to running service' do
      # given
      router_uuid = ROUTER[:uuid]
      stub_request(:get, "#{TUTUM_API_URL}/service/?name=router-sandbox").to_return(:status => 200, :body => ROUTER_RESPONSE_JSON)
      updated_links = {:linked_to_service => [
          {
              :from_service => "/api/v1/service/router-uuid/",
              :name => "web-sandbox",
              :to_service => "/api/v1/service/blue-uuid/"
          },
          {
              :from_service => "/api/v1/service/router-uuid/",
              :name => "irrelevant",
              :to_service => "/api/v1/service/irrelevant_linked_service/"
          }]
      }
      updated_links_json = JSON.generate(updated_links)
      stub_request(:patch, "#{TUTUM_API_URL}/service/#{router_uuid}/")
          .with(:body => updated_links_json)
          .to_return(:status => 200, :body => updated_links_json)

      # when
      response = connection.router_switch("router-sandbox", SERVICE_RUNNING)

      # then
      expect(response).to eq(updated_links)
    end

    it 'should not switch router to stopped service' do
      begin
        connection.router_switch("router-sandbox", SERVICE_STOPPED)
      rescue Exception => ex
        # then
        expect(ex.status).to be(1)
      end
    end

  end
end


