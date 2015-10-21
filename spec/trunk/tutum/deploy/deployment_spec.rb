require 'rspec'
require 'webmock/rspec'
require 'json'
require 'trunk/tutum/deploy/deployment'
require 'trunk/tutum/test_fixtures'

describe Trunk::Tutum::Deploy::Deployment do
  include TestFixtures

  subject(:deployment) { Trunk::Tutum::Deploy::Deployment.new(TestFixtures::TUTUM_API, "web-sandbox", "v2", "ping") }

  describe 'When deploying a service' do

    it 'should get candidates with one service running and one stopped' do
      # given
      stub_request(:get, "#{TestFixtures::TUTUM_API_URL}/service/?name=web-sandbox")
          .to_return(:status => 200, :body => TestFixtures::SERVICES_JSON)

      # when
      deployment.get_candidates

      # then
      expect(deployment.to_shutdown).to eq(TestFixtures::SERVICES[:objects][0])
      expect(deployment.to_deploy).to eq(TestFixtures::SERVICES[:objects][1])
    end

    it 'should get candidates with both stopped' do
      # given
      BOTH_STOPPED = {:meta => {}, :objects => [TestFixtures::SERVICE_STOPPED, TestFixtures::SERVICE_STOPPED]}

      stub_request(:get, "#{TestFixtures::TUTUM_API_URL}/service/?name=web-sandbox")
          .to_return(:status => 200, :body => JSON.generate(BOTH_STOPPED))

      # when
      deployment.get_candidates

      # then
      expect(deployment.to_shutdown).to be_nil
      expect(deployment.to_deploy).to eq(TestFixtures::SERVICE_STOPPED)
    end

    it 'should get candidates when not running' do
      # given
      NOT_RUNNING = {:meta => {}, :objects => [
          {:state => 'Not running'},
          {:state => 'Not running'}
      ]}

      stub_request(:get, "#{TestFixtures::TUTUM_API_URL}/service/?name=web-sandbox")
          .to_return(:status => 200, :body => JSON.generate(NOT_RUNNING))

      # when
      deployment.get_candidates

      # then
      expect(deployment.to_shutdown).to be_nil
      expect(deployment.to_deploy).to eq({:state => 'Not running'})
    end

    it 'no candidate when both running' do
      # given
      BOTH_RUNNING = {:meta => {}, :objects => [TestFixtures::SERVICE_RUNNING, TestFixtures::SERVICE_RUNNING]}

      stub_request(:get, "#{TestFixtures::TUTUM_API_URL}/service/?name=web-sandbox")
          .to_return(:status => 200, :body => JSON.generate(BOTH_RUNNING))

      # when
      deployment.get_candidates

      # then
      expect(deployment.to_deploy).to be_nil
      expect(deployment.to_shutdown).to eq(TestFixtures::SERVICE_RUNNING)
    end

    it 'should redeploy with updated image' do
      # given
      service_uuid = TestFixtures::SERVICE_STOPPED[:uuid]
      deploy_image = "trunk/web-sandbox:v2"

      stub_request(:get, "#{TestFixtures::TUTUM_API_URL}/service/?name=web-sandbox")
          .to_return(:status => 200, :body => TestFixtures::SERVICES_JSON)
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
    it 'should switch router to running service' do
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
        expect(ex.message).to eq("deployed service web-sandbox is not running")
      end
    end

  end
end


