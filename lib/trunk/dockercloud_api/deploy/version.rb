module Trunk
  module DockercloudApi
    module Deploy
      def self.version
        return "1.0.#{ENV['SNAP_PIPELINE_COUNTER']}" if ENV['SNAP_PIPELINE_COUNTER']
        '1.latest'
      end
      VERSION = version
    end
  end
end
