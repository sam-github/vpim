=begin
  Copyright (C) 2009 Sam Roberts

  This library is free software; you can redistribute it and/or modify it
  under the same terms as the ruby language itself, see the file COPYING for
  details.
=end

require 'sinatra'
require 'vpim/repo'
require 'vpim/agent/atomize'

Atomize = Vpim::Agent::Atomize

get '/ics/:form' do
  form = params[:form]
  from = env['QUERY_STRING']

  repo = Vpim::Repo::Uri.new(from)
  cal = repo.find{true}
  
  content_type Atomize::MIME
  body Atomize.new(cal).get
end

