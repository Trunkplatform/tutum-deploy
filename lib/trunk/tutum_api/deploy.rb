require 'tutum'
require 'trunk/tutum_api/api_helper'
require 'trunk/tutum_api/deploy/deployment'
require 'trunk/tutum_api/deploy/version'

require 'trunk/tutum_api/extensions/tutum_api'

class TutumApi
  include Extensions::TutumApi
end