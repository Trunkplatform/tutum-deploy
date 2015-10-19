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
      blue_green = deployment.decide_bluegreen("web-sandbox")

      # then
      expect(blue_green[:to_shutdown]).to eq(TestFixtures::SERVICES_RESPONSE_HASH[:objects][0])
      expect(blue_green[:to_deploy]).to eq(TestFixtures::SERVICES_RESPONSE_HASH[:objects][1])
    end

    it 'should start with updated image' do
      # given
      service_uuid = TestFixtures::SERVICE_STOPPED[:uuid]
      deploy_image = "trunk/web-sandbox:v2"

      stub_request(:get, "#{TestFixtures::TUTUM_API_URL}/service/?name=web-sandbox")
          .to_return(:status => 200, :body => TestFixtures::SERVICES_RESPONSE_JSON)
      stub_request(:patch, "#{TestFixtures::TUTUM_API_URL}/service/#{service_uuid}/")
          .with(:body => "{\"image_name\":\"#{deploy_image}\"}")
          .to_return(:status => 200, :body => "{}")
      stub_request(:post, "#{TestFixtures::TUTUM_API_URL}/service/#{service_uuid}/start/").to_return(:status => 200, :body => "{}")

      # when
      deployment.deploy(TestFixtures::SERVICE_STOPPED, "v2")

      # then
      # expect(connection.session).to receive(update).with(@service_uuid, :image_name => @deploy_image)
      # expect(connection.session).to receive(start).with(@service_uuid)
    end

    it 'should wait for healthy service and run block' do
      # given
      stub_request(:get, "http://#{TestFixtures::SERVICE_RUNNING[:public_dns]}/ping").to_return(:status => 200, :body => "{}")
      stub_request(:get, "#{TestFixtures::TUTUM_API_URL}/service/#{TestFixtures::SERVICE_RUNNING[:uuid]}/")
          .to_return(:status => 200, :body => JSON.generate(TestFixtures::SERVICE_RUNNING))

      # when
      deployment.wait_for_healthy(TestFixtures::SERVICE_RUNNING, "ping") { |healthy|
        # then
        expect(healthy).to eq(TestFixtures::SERVICE_RUNNING)
      }
    end

    it 'should timeout after max wait' do
      # given
      stub_request(:get, "http://#{TestFixtures::SERVICE_RUNNING[:public_dns]}/ping").to_return(:status => 503, :body => "{}")

      # when
      begin
        deployment.wait_for_healthy(TestFixtures::SERVICE_RUNNING, "ping")
      rescue Exception => ex
        # then
        expect(ex.status).to be(1)
      end
    end

    it 'should switch router to running service' do
      # given
      router_uuid = TestFixtures::ROUTER[:uuid]
      stub_request(:get, "#{TestFixtures::TUTUM_API_URL}/service/?name=router-sandbox")
          .to_return(:status => 200, :body => TestFixtures::ROUTER_RESPONSE_JSON)
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
      stub_request(:patch, "#{TestFixtures::TUTUM_API_URL}/service/#{router_uuid}/")
          .with(:body => updated_links_json)
          .to_return(:status => 200, :body => updated_links_json)

      # when
      response = deployment.router_switch("router-sandbox", TestFixtures::SERVICE_RUNNING)

      # then
      expect(response).to eq(updated_links)
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


