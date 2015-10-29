require 'rspec'
require 'webmock/rspec'
require 'json'
require 'trunk/tutum_api/api_helper'
require 'trunk/tutum_api/test_fixtures'

describe Trunk::TutumApi::ApiHelper  do
  include TestFixtures

  subject(:api_helper) { TestFixtures::ApiHelperStub.new(TestFixtures::TUTUM_API) }

  describe 'Service API' do

    it 'should convert symbolized hash' do
      # given
      stub_request(:get, "#{TestFixtures::TUTUM_API_URL}/service/?name=web-sandbox")
          .to_return(:status => 200, :body => TestFixtures::SERVICES_JSON)

      # when
      services = api_helper.services("web-sandbox")

      # then
      expect(services).to eq(TestFixtures::SERVICES[:objects])
    end

    it 'should ping for healthy service' do
      # given
      stub_request(:get, "http://test/ping").to_return(:status => 200, :body => "{}")

      # when
      api_helper.healthy?("http://test/ping") { |result|
        # then
        expect(result).to be_truthy
      }
    end

    it 'health check should timeout after max wait' do
      # given
      stub_request(:get, "http://test/ping").to_return(:status => 503, :body => "{}")

      # when
      begin
        api_helper.healthy?("http://test/ping")
      rescue Exception => ex
        # then
        expect(ex.status).to be(1)
      end
    end

    it 'http ping path should use be pass through' do
      # given
      ping_url = "https://hello.com/world"

      # when
      ping_url = api_helper.ping_url(nil, ping_url)

      # then
      expect(ping_url).to eq(ping_url)
    end

    it 'non http ping path should build a url' do
      # given
      service = {:public_dns=>"hello.com"}
      ping_path = "ping"

      # when
      ping_url = api_helper.ping_url(service, ping_path)

      # then
      expect(ping_url).to eq("http://hello.com/ping")
    end

    it 'proxy_path should be appended when exists' do
      # given
      service = {:public_dns=>"hello.world.trunkbot.svc.tutum.io"}
      ping_path = "admin/ping"
      proxy_path = "https://proxy-dev.trunkplatform.com.au/proxy/"

      # when
      ping_url = api_helper.ping_url(service, ping_path, proxy_path)

      # then
      expect(ping_url).to eq("https://proxy-dev.trunkplatform.com.au/proxy/hello.world/admin/ping")
    end

  end

  describe 'Action API' do
    it 'should return Action Success' do
      # given
      stub_request(:get, "https://dashboard.tutum.co/api/v1/action/action_success/")
          .to_return(:status => 200,
                     :body => JSON.generate(TestFixtures::ACTION_SUCCESS))

      # when
      api_helper.completed?("/api/v1/action/action_success/") {|action_state|
        #then
        expect(action_state).to eq("Success")
      }
    end

    it 'should return Action Failure' do
      # given
      stub_request(:get, "https://dashboard.tutum.co/api/v1/action/action_failed/")
          .to_return(:status => 200,
                     :body => JSON.generate(TestFixtures::ACTION_FAILED))

      # when
      api_helper.completed?("/api/v1/action/action_failed/") {|action_state|
        #then
        expect(action_state).to eq("Failed")
      }
    end

  end
end

