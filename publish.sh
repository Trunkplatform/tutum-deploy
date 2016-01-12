#!/bin/bash

gem build tutum-deploy.gemspec && \
gem install geminabox --no-doc --no-ri  && \
gem inabox tutum-deploy*.gem -g "https://${GEMINABOX_USER}:${GEMINABOX_PASSWORD}@gems.trunkplatform.com.au"
