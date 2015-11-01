# Tutum Deploy

A rake file to help out with zero down time deployments for a Tutum service across 2 stacks with health checks.

Follows the same principles described in [Blue-Green Deployment using Containers]
(http://blog.tutum.co/2015/06/08/blue-green-deployment-using-containers/) However with some improvements:

 1. Keeps the service name the same but across different stacks. I.e. instead of web-blue and web-green, 
 use web.blue-stack and web.green-stack. Also keeps your stack files slightly by avoiding duplicate services in the same file.
 2. Does healthchecks via ping url. Because just because a container has finished deployment, doesn't mean the service
 is up and running.

## Overview

Given

   a-service.stack-blue -> Running
   a-service.stack-green -> Stopped
   a-haproxy-router -> Running

This gem will:
 
 1. find the deployment candidates:
   - deploy `a-service.stack-green`
   - stop `a-service.stack-blue` upon successful and healthy deployment
 2. update `a-service.stack-green` to the specified version and redeploy the service
 4. do health check by pinging `a-service.stack-green` using it's public dns or hostname (see below)
 5. upon healthy status, stop the `a-service.stack-blue`

## Installation

Add this line to your application's Gemfile:

    gem 'tutum-deploy'

Add this line to your rake file:

    deploy_spec = Gem::Specification.find_by_name 'tutum-deploy'
    Dir.glob("#{deploy_spec.gem_dir}/lib/tasks/*.rake").each {|r| import r }

And then execute:

    $ bundle

## Usage

### Configuration
The following environment variables needs to be provided:

    TUTUM_USER
    TUTUM_APIKEY
    PROXY_PATH (Optional) - a proxy server into your overlay network. Example: https://github.com/Trunkplatform/nginx-overlay-proxy
    SLEEP_INTERVAL (Optional interval between polling, defaults to 5 seconds)
    MAX_TIMEOUT (Optional maximum timeout when waiting for actions, defaults to 120 seconds)

### Single Stack
Simple single service deployment:

    bundle exec rake --trace tutum:single_stack_deploy[service_name,version,ping_uri,ping_port]
    
Dual stack service deployment:

    bundle exec rake --trace tutum:dual_stack_deploy[dual-stack-service,latest,router-name,admin/ping,8080]

Where

 - service

For example: 

### Health Check URL
The ping url is resolved in the following way:

