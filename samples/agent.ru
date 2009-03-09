#!/usr/bin/env ruby
# Run as "rackup agent.ru", default rackup arguments follow:
#\ -p 4567

require "vpim/agent/ics"

use Rack::Reloader, 0

run Vpim::Agent::Ics

