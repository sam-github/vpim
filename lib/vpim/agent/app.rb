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

require 'cgi'

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

get '/ics' do
  from = env['QUERY_STRING']

  url = URI.parse(request.url)
  url.query = nil
  url_base = url.to_s
  url_atom = nil

  @url_ics  = from      # ics from here
  @url_atom = nil

  if not from.empty?
    # Error out if we can't atomize the feed
    Vpim::Agent::App.atomize(from, "http://example.com")

    url = URI.parse(request.url)
    url.path << "/atom"
    url_atom = url.to_s
  end

  @url_base = url_base  # clean input form
  @url_atom = url_atom  # atomized ics from here

  haml :"ics.haml"
end

post '/ics' do
  from = params[:url]
  url = URI.parse(request.url)
  url.query = from
  redirect url.to_s
end

# When we support other forms..
#get '/ics/:form' do
#  form = params[:form]
get '/ics/atom' do
  from = env['QUERY_STRING']
  port = env["SERVER_PORT"].to_i
  here = request.url

  if from.empty?
    url = URI.parse(here)
    url.path.sub(/atom$/, "")
    redirect here.to_s
  end

  xml, xmltype = Vpim::Agent::App.atomize(from, here)

  content_type xmltype
  body xml
end

get '/ics/style.css' do
  content_type 'text/css'
  sass :"ics.sass"
end

error do
  @url_error = CGI.escapeHTML(env['sinatra.error'].inspect)
  haml :"ics.haml"
end

use_in_file_templates!

# FIXME - hard-coded :action paths below, bad!

__END__
@@ics.sass
body
  :background-color gray
  :font-size medium
  a
    :color black
    :font-style italic
  a:hover
    :color darkred

#header
  :border-bottom 3px solid darkred
  #title
    :color black
    :font-size large

.text
  :width 80%
-#:color yellow

#submit
  :margin-top 30px
  :margin-left 5%
  #form
    :padding
      :top 10px
      :bottom 10px
      :left 10px
      :right 10px
    :text-align left
    #url
      :width 80%
    #button
      :font-weight bold
      :text-align center

#subscribe
  :margin-left 5%
-#.feed
-#  :margin-left 10%
  
#footer
  :border-top 3px solid darkred
  :margin-top 20px
@@ics.haml
%html
  %head
    %title Subscribe to calendar feeds as atom feeds
    %link{:href => '/ics/style.css', :media => 'screen', :type => 'text/css'}
  %body
    #header
      %span#title Subscribe to calendar feeds as atom feeds
    #submit
      .text Calendar feeds are great, but sometimes all you want is an atom feed of what's coming up in the next week.
      .text Paste the URL of the calendar below, submit it, and subscribe.
      %form#form{:method => 'POST', :action => '/ics'}
        %input#url{:name => 'url', :value => params[:url]}
        %input#button{:type => 'submit', :value => 'Submit'}
    - if @url_atom
      #subscribe
        .text
          Subscribe to
          %a{:href => @url_ics}= @url_ics
          as:
        %ul.feed
          %a{:href => @url_atom}= @url_atom
          (atom feed)
    - if @url_error
      #error.text
        #preamble Sorry, trying to access:
        #source= @url_ics
        #transition resulted in:
        #destination= @url_error
    #footer
      .text
        :textile
          Coming from the "Octet Cloud":http://octetcloud.com/ using "vPim":http://vpim.rubyforge.org/, piloted by cloud monkey "Sam Roberts":mailto:vieuxtech@gmail.com

