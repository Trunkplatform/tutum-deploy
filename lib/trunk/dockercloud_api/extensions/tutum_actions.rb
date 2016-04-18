module Extensions
  module TutumActions

    def self.included(klass)
      klass.class_eval do
        def list_url
          "/action/"
        end

        def list(params)
          http_get(list_url, params)
        end

        def get_url(uuid)
          "/action/#{uuid}/"
        end

        def get(uuid)
          http_get(get_url(uuid))
        end
      end
    end

  end
end