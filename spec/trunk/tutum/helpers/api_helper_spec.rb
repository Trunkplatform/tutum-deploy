require 'rspec'
require 'webmock/rspec'
require 'json'
require 'trunk/tutum/api_helper'
require 'trunk/tutum/test_fixtures'

describe Trunk::Tutum::ApiHelper  do
  include TestFixtures

  subject(:api_helper) { TestFixtures::ApiHelperStub.new(TestFixtures::TUTUM_API) }

  describe 'Service API' do

    it 'should convert symbolized hash' do
      # given
      stub_request(:get, "#{TestFixtures::TUTUM_API_URL}/service/?name=web-sandbox")
          .to_return(:status => 200, :body => TestFixtures::SERVICES_RESPONSE_JSON)

      # when
      services = api_helper.get_services("web-sandbox")

      # then
      expect(services).to eq(TestFixtures::SERVICES_RESPONSE_HASH[:objects])
    end
  end
end

