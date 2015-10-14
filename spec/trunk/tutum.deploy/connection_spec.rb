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

    SERVICES_RESPONSE_HASH = {
        :meta => {},
        :objects => [{
                         :uuid => "123",
                         :image_name => "trunk/web-sandbox:v1",
                         :name => "web-sandbox",
                         :stack => "/api/v1/stack/82068828-3a49-40fc-b614-e41ad64b846f/",
                         :state => "Running",
                     }, {
                         :uuid => "466",
                         :image_name => "trunk/web-sandbox:v1",
                         :name => "web-sandbox",
                         :stack => "/api/v1/stack/c8c57cfa-658d-4d28-9ee4-d6193eff0621/",
                         :state => "Stopped",
                     }]
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

    it 'should start with updated image' do
      # given
      service = SERVICES_RESPONSE_HASH[:objects][1]
      service_uuid = service[:uuid]
      deploy_image = "trunk/web-sandbox:v2"

      stub_request(:get, "#{TUTUM_API_URL}/service/?name=web-sandbox").to_return(:status => 200, :body => SERVICES_RESPONSE_JSON)
      stub_request(:patch, "#{TUTUM_API_URL}/service/#{service_uuid}/")
          .with(:body => "{\"image_name\":\"#{deploy_image}\"}")
          .to_return(:status => 200, :body => "{}")
      stub_request(:post, "#{TUTUM_API_URL}/service/#{service_uuid}/start/").to_return(:status => 200, :body => "{}")

      # when
      connection.deploy(service, "v2")

      # then
      # expect(connection.session).to receive(update).with(@service_uuid, :image_name => @deploy_image)
      # expect(connection.session).to receive(start).with(@service_uuid)
    end

    it 'should wait for healthy service' do
      # given
      service = SERVICES_RESPONSE_HASH[:objects][1]
      stub_request(:get, "ping").to_return(:status => 200, :body => "{}")

      # when
      result = connection.wait_for_healthy(service, "ping", 5, 10)

      # then
      expect(result).to be(0)
    end

    it 'should timeout after max wait' do
      # given
      service = SERVICES_RESPONSE_HASH[:objects][1]

      # when
      begin
        connection.wait_for_healthy(service, "ping", 5, 1)
      rescue Exception => ex
        # then
        expect(ex.status).to be(1)
      end
    end

    it 'should relink router' do

    end

    it 'should stop old service' do

    end
  end
end


