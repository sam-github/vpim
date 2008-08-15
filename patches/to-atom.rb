#!/usr/bin/env ruby

$-w = true

require 'atom'
require 'webrick'

module XML
  class Reader
  end
end

$id = 0

def id
  "http://example.org/#{$id+=1}"
end

def atomize
  f = Atom::Feed.new
  f.title = "Feed Title"
  f.links << Atom::Link.new(:href => "http://localhost:8080", :rel => "self")
  f.updated = Time.now
  f.authors << Atom::Person.new(:name => "Feed Author")
  f.id = id
  f.entries << Atom::Entry.new do |e|
    e.title = "Entry Title"
    e.links << Atom::Link.new(:href => "http://example.org/")
    e.updated = Time.now
    e.content = Atom::Content::Html.new "Html Content"
    e.id = id
    e.authors << Atom::Person.new(:name => "Entry Author")
  end
  f.to_xml
end

if ARGV.first == "-"
  puts atomize
else

  class Feed < WEBrick::HTTPServlet::AbstractServlet
    def do_GET(req, resp)   
      resp.body = atomize
      resp["content-type"] = "application/atom+xml"
      #raise WEBrick::HTTPStatus::OK
    end
  end

  server = WEBrick::HTTPServer.new( :Port => 8080 )

  server.mount( "/", Feed )

  ['INT', 'TERM'].each { |signal| 
    trap(signal) { server.shutdown }
  }

  server.start
end

