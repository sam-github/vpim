=begin
  Copyright (C) 2009 Sam Roberts

  This library is free software; you can redistribute it and/or modify it
  under the same terms as the ruby language itself, see the file COPYING for
  details.
=end

require 'sinatra'
require 'vpim/agent/atomize'
require 'vpim/repo'
require 'vpim/view'

configure do
  server = Sinatra::Application.server
  set :server, Proc.new {
      if ENV.include?("PHP_FCGI_CHILDREN")
        break "fastcgi" # Must NOT be the correct class name!
      elsif ENV.include?("REQUEST_METHOD")
        break "cgi" # Must NOT be the correct class name!
      else
        # Fall back on whatever it was going to be.
        server
      end
  }
end

# I could wrap the Repo/Calendar/Atomize in a small class that would memoize
# ical data and atom output. Maybe even do an HTTP head for fast detection of
# change? Does a calendar have updated information? Can we memoize atom when
# ics doesn't change?

module Vpim
  module Agent
    module App
      def self.atomize(caluri, feeduri)
        repo = Vpim::Repo::Uri.new(caluri)
        cal = repo.find{true}
        cal = View.week(cal)
        feed = Agent::Atomize.calendar(cal, feeduri, caluri, cal.name)
        return feed.to_xml,  Agent::Atomize::MIME
      end
    end
  end
end

# When we support other forms..
#get '/ics/:form' do
  #form = params[:form]
get '/ics/atom' do
  from = env['QUERY_STRING']
  port = env["SERVER_PORT"].to_i
  here = request.url

  xml, xmltype = Vpim::Agent::App.atomize(from, here)

  content_type xmltype
  body xml
end

