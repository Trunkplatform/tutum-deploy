require 'rest-client'

module Extensions
  module TutumApi

    def self.included(klass)
      klass.class_eval do
        attr_reader :headers

        def initialize(headers, json_opts = {:symbolize_names => true})
          @headers = headers
          @json_opts = json_opts
          RestClient.log = Logger.new($stdout)
        end

        def app_url(path)
          'https://cloud.docker.com/api/app/v1' + path
        end

        def url(path)
          if path.include? 'action'
            audit_url(path)
          else
            app_url(path)
          end
        end

        def audit_url(path)
          'https://cloud.docker.com/api/audit/v1' + path
        end

        def http_get(path, params={})
          query =  "?" + params.map { |k,v| "#{k}=#{v}"}.join("&")
          full_path = path
          full_path += query unless params.empty?
          response = RestClient.get(url(full_path), headers)
          JSON.parse(response, @json_opts)
        end

        def http_post(path, content={}, sync=false)
          response = RestClient.post(url(path), content.to_json, headers)
          # puts "Headers: #{response.headers}" unless response.headers[:x_dockercloud_action_uri]
          {:action_uri => response.headers[:x_dockercloud_action_uri], :body => JSON.parse(response.body, @json_opts)}
        end

        def http_patch(path, content={}, sync=false)
          response = RestClient.patch(url(path), content.to_json, headers)
          # puts "Headers: #{response.headers}" unless response.headers[:x_dockercloud_action_uri]
          {:action_uri => response.headers[:x_dockercloud_action_uri], :body => JSON.parse(response.body, @json_opts)}
        end

        def http_delete(path, sync=false)
          response = RestClient.delete(url(path), headers)
          # puts "Headers: #{response.headers}" unless response.headers[:x_dockercloud_action_uri]
          {:action_uri => response.headers[:x_dockercloud_action_uri], :body => JSON.parse(response.body, @json_opts)}
        end
      end
    end
  end
end
