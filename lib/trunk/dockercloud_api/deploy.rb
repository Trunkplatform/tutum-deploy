require 'trunk/dockercloud_api/deploy/deployment'
require 'trunk/dockercloud_api/api_helper'
require 'trunk/dockercloud_api/deploy/version'

require 'tutum'
require 'trunk/dockercloud_api/extensions/tutum'
require 'trunk/dockercloud_api/extensions/tutum_api'
require 'trunk/dockercloud_api/extensions/tutum_actions'

class TutumActions
  include Extensions::TutumActions
end

class TutumApi
  include Extensions::TutumApi
end

class Tutum
  include Extensions::Tutum
end