require 'rspec'
require 'webmock/rspec'
require 'json'
require 'trunk/tutum/deploy/deployment'
require 'trunk/tutum/test_fixtures'

describe Trunk::Tutum::Deploy::Deployment do
  include TestFixtures

  subject(:deployment) { Trunk::Tutum::Deploy::Deployment.new(TestFixtures::TUTUM_API, 1, 2) }

  describe 'when deploying a service' do

    it 'should decide blue or green' do
      # given
      stub_request(:get, "#{TestFixtures::TUTUM_API_URL}/service/?name=web-sandbox")
          .to_return(:status => 200, :body => TestFixtures::SERVICES_RESPONSE_JSON)

      # when
      blue_green = deployment.get_candidates("web-sandbox")

      # then
      expect(blue_green[:to_shutdown]).to eq(TestFixtures::SERVICES_RESPONSE_HASH[:objects][0])
      expect(blue_green[:to_deploy]).to eq(TestFixtures::SERVICES_RESPONSE_HASH[:objects][1])
    end

    it 'should redeploy with updated image' do
      # given
      service_uuid = TestFixtures::SERVICE_STOPPED[:uuid]
      deploy_image = "trunk/web-sandbox:v2"

      stub_request(:get, "#{TestFixtures::TUTUM_API_URL}/service/?name=web-sandbox")
          .to_return(:status => 200, :body => TestFixtures::SERVICES_RESPONSE_JSON)
      stub_request(:patch, "#{TestFixtures::TUTUM_API_URL}/service/#{service_uuid}/")
          .with(:body => "{\"image\":\"#{deploy_image}\"}")
          .to_return(:status => 200, :body => "{}")
      stub_request(:post, "#{TestFixtures::TUTUM_API_URL}/service/#{service_uuid}/redeploy/")
          .to_return(:status => 200,
                     :headers => {:x_tutum_action_uri => "/api/v1/action/action_success/"},
                     :body => JSON.generate(TestFixtures::ACTION_SUCCESS))

      # when
      response = deployment.deploy(TestFixtures::SERVICE_STOPPED, "v2")

      # then
      expect(response).to eq(TestFixtures::ASYNC_RESPONSE)

    end

    it 'should switch router to running service' do
      # given
      router_uuid = TestFixtures::ROUTER[:uuid]
      stub_request(:get, "#{TestFixtures::TUTUM_API_URL}/service/?name=router-sandbox")
          .to_return(:status => 200, :body => TestFixtures::ROUTER_RESPONSE_JSON)
      updated_links = {
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
          }]
      }
      updated_links_json = JSON.generate(updated_links)
      stub_request(:patch, "#{TestFixtures::TUTUM_API_URL}/service/#{router_uuid}/")
          .with(:body => updated_links_json)
          .to_return(:status => 200, :body => updated_links_json)

      # when
      response = deployment.router_switch("router-sandbox", TestFixtures::SERVICE_RUNNING)

      # then
      expect(response[:body]).to eq(updated_links)
    end

    it 'should not switch router to stopped service' do
      begin
        deployment.router_switch("router-sandbox", TestFixtures::SERVICE_STOPPED)
      rescue Exception => ex
        # then
        expect(ex.status).to be(1)
      end
    end

  end
end


