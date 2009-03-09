=begin
  Copyright (C) 2009 Sam Roberts

  This library is free software; you can redistribute it and/or modify it
  under the same terms as the ruby language itself, see the file COPYING for
  details.
=end

require 'cgi'

require 'vpim/agent/atomize'
require 'vpim/repo'
require 'vpim/view'

require 'sinatra/base'

# http://agent.octetcloud.com/atom?http://www.mozilla.org/projects/calendar/caldata/CanadaHolidays.ics

# TODO Rename templates to agent/ics/sass and agent/ics/haml
# TODO Move code into methods
module Vpim
  module Agent

    class Ics < Sinatra::Base
      use_in_file_templates!

      # TODO - move following into Agent/Servlet base class
      def css # < Agent
        content_type 'text/css'
        options.templates[:"servlet/css"]
      end

      # Complete path, as requested by the client. Take care for CGI path rewriting.
      def request_path # < Agent
        # Using .to_s because rack/request.rb does, though I think the Rack
        # spec requires these to be strings already.
        begin
          URI.parse(env["SCRIPT_URI"].to_s).path
        rescue
          env["SCRIPT_NAME"].to_s + env["PATH_INFO"].to_s
        end
      end

      # Complete path, as requested by the client, without the env's PATH_INFO.
      # This is the path to whatever is "handling" the request.
      def script_path # < Agent
        request_path.sub(/#{env["PATH_INFO"]}$/, "")
      end

      # URL-ready form of the host and port, where the port isn't specified if
      # it is the default for the URL scheme.
      def host_port # < Agent
        r = request
        host_port = r.host

        if r.scheme == "https" && r.port != 443 ||
          r.scheme == "http" && r.port != 80
          host_port << ":#{r.port}"
        end

        host_port
      end

      # URL to the script
      def script_url # < Agent
        request.scheme + "://" + host_port + script_path
      end

      def atomize(caluri, feeduri)
        repo = Vpim::Repo::Uri.new(caluri)
        cal = repo.find{true}
        cal = View.week(cal)
        feed = Agent::Atomize.calendar(cal, feeduri, caluri, cal.name)
        return feed.to_xml,  Agent::Atomize::MIME
      end

      get '/?' do

        from = env['QUERY_STRING']

        @url_base = script_url   # agent mount point
        @url_ics  = from         # ics from here
        @url_atom = nil          # atom feed from here, if ics is accessible
        @url_error= nil          # error message, if is is not accessible

        if not from.empty?
          begin
            atomize(from, "http://example.com")
            @url_atom = @url_base + "/atom" + "?" + from
          rescue
            @url_error = CGI.escapeHTML($!.to_s)
          end
        end

        haml :"ics.haml"
      end

      post "/?" do
        redirect script_url + "?" + (params[:url] || "")
      end

      # When we support other forms..
      #get '/ics/:form' do
      #  form = params[:form]
      get "/atom" do
        caluri = env['QUERY_STRING']

        if caluri.empty?
          redirect script_url
        end

        feeduri = script_url + "/atom?" + caluri

        begin
          xml, xmltype = atomize(caluri, feeduri)
          content_type xmltype
          body xml
        rescue
          redirect script_url + "?" + caluri
        end
      end

      get '/style.css' do
        content_type 'text/css'
        sass :"ics.sass"
      end
    end

  end # Agent
end # Vpim


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
    %link{:href => script_url + '/style.css', :media => 'screen', :type => 'text/css'}
  %body
    #header
      %span#title Subscribe to calendar feeds as atom feeds
    #submit
      .text Calendar feeds are great, but sometimes all you want is an atom feed of what's coming up in the next week.
      .text Paste the URL of the calendar below, submit it, and subscribe.
      .text= [script_url, env["SCRIPT_NAME"], env["PATH_INFO"]].inspect
      %form#form{:method => 'POST'}
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

