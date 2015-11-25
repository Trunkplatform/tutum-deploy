require 'rspec'
require 'webmock/rspec'
require 'json'
require 'trunk/tutum_api/deploy/deployment'
require 'trunk/tutum_api/test_fixtures'

describe Trunk::TutumApi::Deploy::Deployment do
  include TestFixtures

  subject(:deployment) { Trunk::TutumApi::Deploy::Deployment.new(TestFixtures::TUTUM_API, "web-sandbox", "v2", "ping") }

  before(:each) do
    TestFixtures::SERVICE_BLUE[:state] = 'Running'
    TestFixtures::SERVICE_GREEN[:state] = 'Stopped'
  end

  describe 'When deploying a service' do

    it 'should get candidates based on router links' do
      #given
      stub_request(:get, "#{TestFixtures::TUTUM_API_URL}/service/?name=web-sandbox")
          .to_return(:status => 200, :body => TestFixtures::SERVICES_JSON)

      router_uuid = TestFixtures::ROUTER[:uuid]
      stub_request(:get, "#{TestFixtures::TUTUM_API_URL}/service/?name=router-sandbox")
          .to_return(:status => 200, :body => TestFixtures::ROUTERS_JSON)
      stub_request(:get, "#{TestFixtures::TUTUM_API_URL}/service/#{router_uuid}/")
          .to_return(:status => 200, :body => JSON.generate(TestFixtures::ROUTER))

      #when
      deployment.get_candidates('router-sandbox')

      #then
      expect(deployment.to_shutdown).to eq(TestFixtures::SERVICES[:objects][0])
      expect(deployment.to_deploy).to eq(TestFixtures::SERVICES[:objects][1])
    end

    it 'should redeploy with updated image' do
      # given
      service_uuid = TestFixtures::SERVICE_BLUE[:uuid]
      deploy_image = "trunk/web-sandbox:v2"

      stub_request(:get, "#{TestFixtures::TUTUM_API_URL}/service/?name=web-sandbox")
          .to_return(:status => 200, :body => TestFixtures::SERVICE_JSON)
      stub_request(:patch, "#{TestFixtures::TUTUM_API_URL}/service/#{service_uuid}/")
          .with(:body => "{\"image\":\"#{deploy_image}\"}")
          .to_return(:status => 200, :body => "{}")
      stub_request(:post, "#{TestFixtures::TUTUM_API_URL}/service/#{service_uuid}/redeploy/")
          .to_return(:status => 200,
                     :headers => {:x_tutum_action_uri => "/api/v1/action/action_success/"},
                     :body => JSON.generate(TestFixtures::ACTION_SUCCESS))

      # when
      response = deployment.get_candidates.deploy

      # then
      expect(response).to eq(TestFixtures::ASYNC_RESPONSE)

    end

  end

  describe 'When deploying service in single stack' do

  end

  describe 'When deploying service in dual stacks' do
    it 'should switch router to deployed service' do
      # given
      router_uuid = TestFixtures::ROUTER[:uuid]
      stub_request(:get, "#{TestFixtures::TUTUM_API_URL}/service/?name=router-sandbox")
          .to_return(:status => 200, :body => TestFixtures::ROUTERS_JSON)
      stub_request(:get, "#{TestFixtures::TUTUM_API_URL}/service/router-uuid/")
          .to_return(:status => 200, :body => JSON.generate(TestFixtures::ROUTER))

      updated_links = {
          :linked_to_service => [
          {
              :from_service => "/api/v1/service/router-uuid/",
              :name => "web-sandbox-green",
              :to_service => "/api/v1/service/green-uuid/"
          },
          {
              :from_service => "/api/v1/service/router-uuid/",
              :name => "irrelevant-blue",
              :to_service => "/api/v1/service/irrelevant_linked_service/"
          }]
      }
      updated_links_json = JSON.generate(updated_links)
      stub_request(:patch, "#{TestFixtures::TUTUM_API_URL}/service/#{router_uuid}/")
          .with(:body => updated_links_json)
          .to_return(:status => 200,
                     :headers => {:x_tutum_action_uri => "/api/v1/action/action_uuid/"},
                     :body => updated_links_json)

      stub_request(:get, "#{TestFixtures::TUTUM_API_URL}/action/action_uuid/").
          to_return(:status => 200, :body => "{\"state\": \"Success\"}")


      # when
      service_green = TestFixtures::SERVICE_GREEN;
      service_green[:state] = "Running"
      deployment.router_switch("router-sandbox", service_green){|linked_services|
        # then
        expect(linked_services).to eq(updated_links[:linked_to_service])
      }
    end

    it 'should not switch router to stopped service' do
      begin
        deployment.router_switch("router-sandbox", TestFixtures::SERVICE_GREEN)
      rescue Exception => ex
        # then
        expect(ex.message).to eq("deployed service web-sandbox is not running")
      end
    end

  end
end


