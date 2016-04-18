require 'base64'

module Extensions
  module Tutum

    def self.included(klass)
      klass.class_eval do
        def headers
          {
              'Authorization' => authorization_header,
              'Accept' => 'application/json',
              'Content-Type' => 'application/json'
          }
        end

        def authorization_header
          @tutum_auth ? @tutum_auth : "Basic #{Base64.strict_encode64(@username + ':' + @api_key)}"
        end
      end
    end
  end
end
