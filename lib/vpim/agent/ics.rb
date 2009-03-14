=begin
  Copyright (C) 2009 Sam Roberts

  This library is free software; you can redistribute it and/or modify it
  under the same terms as the ruby language itself, see the file COPYING for
  details.
=end

require 'cgi'

require 'vpim/agent/base'
require 'vpim/agent/atomize'
require 'vpim/repo'
require 'vpim/view'

require 'sinatra/base'

module Vpim
  module Agent

    class Ics < Base
      use_in_file_templates!

      def atomize(caluri, feeduri)
        repo = Vpim::Repo::Uri.new(caluri)
        cal = repo.find{true}
        cal = View.week(cal)
        feed = Agent::Atomize.calendar(cal, feeduri, caluri, cal.name)
        return feed.to_xml,  Agent::Atomize::MIME
      end

      ## Route handlers:
      def get_base(from)
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

        haml :"vpim/agent/ics/view"
      end

      # When we support other forms..
      #get '/ics/:form' do
      #  form = params[:form]
      def get_atom(caluri)
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

      def get_style
        content_type 'text/css'
        css :"vpim/agent/ics/style"
      end

      ## Sinatra routing:
      get '/?' do
        get_base(env['QUERY_STRING'])
      end

      post "/?" do
        redirect script_url + "?" + (params[:url] || "")
      end

      get "/atom" do
        get_atom(env['QUERY_STRING'])
      end

      get '/style.css' do
        get_style
      end

    end # Ics

  end # Agent
end # Vpim

__END__
@@vpim/agent/ics/style
body {
  background-color: gray;
}
h1 {
  border-bottom: 3px solid #8B0000;
  font-size: large;
}
form {
  margin-left: 10%;
}
input.text {
  width: 80%;
}
a {
  color: black;
}
a:hover {
  color: #8B0000;
}
tt {
  margin-left: 10%;
}
.footer {
  border-top: 3px solid #8B0000;
}
@@vpim/agent/ics/view
!!! strict
%html
  %head
    %title Subscribe to calendar feeds as atom feeds
    %link{:href => script_url + "/style.css", :media => "screen", :type => "text/css"}
    %meta{:"http-equiv" => "Content-Type", :content => "text/html;charset=utf-8"}
  %body
    %h1 Subscribe to calendar feeds as atom feeds
    %p
      Calendar feeds are great, but when you want a reminder of what's coming up
      in the next week, you might want those events as an atom feed.
    %p
      Paste the URL of the calendar below, submit it, and subscribe.
    %form{:method => 'POST', :action => script_url}
      %p
        %input.text{:type => 'text', :name => 'url', :value => @url_ics}
        %input{:type => 'submit', :value => 'Submit'}
    - if @url_atom
      %p
        Subscribe to
        %a{:href => @url_ics}= @url_ics
        as:
      %ul.feed
        %li
          %a{:href => @url_atom}= @url_atom
          (atom feed)
    - if @url_error
      %p
        Sorry, trying to access
        %tt=@url_ics
        resulted in:
      %p
        %tt= @url_error
    .footer
      :textile
        Brought from the "Octet Cloud":http://octetcloud.com/ using "vPim":http://vpim.rubyforge.org/, by cloud monkey "Sam Roberts":mailto:vieuxtech@gmail.com.

