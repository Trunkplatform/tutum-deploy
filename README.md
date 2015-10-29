# Trunk::TutumApi::Deploy

A rake file to help out with zero down time deployments for a Tutum service across 2 stacks.

## Installation

Add this line to your application's Gemfile:

    gem 'tutum-deploy'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install tutum-deploy

## Usage

### Configuration
The following environment variables needs to be provided:

    TUTUM_USER
    TUTUM_APIKEY
    PROXY_PATH (Optional)
    SLEEP_INTERVAL (Optional interval between polling, defaults to 5 seconds)
    MAX_TIMEOUT (Optional maximum timeout when waiting for actions, defaults to 120 seconds)

### Single Stack
For services with a single stack, the 

    service_name, version, ping_uri, ping_port(optional, default to 80)

For example: 

    bundle exec rake --trace tutum:single_stack_deploy[single-service,latest,ping,80]

### Dual Stack
For services with 2 stacks, the parameters are:

    service_name, version, router_name, ping_uri, ping_port(optional, default to 80)

For example: 

    bundle exec rake --trace tutum:dual_stack_deploy[dual-stack-service,latest,router-name,admin/ping,8080]