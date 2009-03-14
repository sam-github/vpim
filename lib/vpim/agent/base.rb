=begin
  Copyright (C) 2009 Sam Roberts

  This library is free software; you can redistribute it and/or modify it
  under the same terms as the ruby language itself, see the file COPYING for
  details.
=end

require 'cgi'

require 'sinatra/base'

# TODO Pasting of webcal links, conversion to webcal links?

module Vpim
  module Agent

    class Base < Sinatra::Base
      # Ensure that this happens...
      set :haml, :format=>:html4 # Appears to do nothing, but maybe it will some day...

      def css(template)
        render :css, template, {}
      end

      def render_css(template, data, options) # :nodoc:
        data
      end

      # Complete path, as requested by the client. Take care about CGI path rewriting.
      def request_path
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
      #
      # Recent discussions on how PATH_INFO must be decoded leads me to think
      # this might not work if the path had any URL encoded characters in it.
      def script_path
        request_path.sub(/#{env["PATH_INFO"]}$/, "")
      end

      # URL-ready form of the host and port, where the port isn't specified if
      # it is the default for the URL scheme.
      def host_port
        r = request
        host_port = r.host

        if r.scheme == "https" && r.port != 443 ||
          r.scheme == "http" && r.port != 80
          host_port << ":#{r.port}"
        end

        host_port
      end

      # URL to the script
      def script_url
        request.scheme + "://" + host_port + script_path
      end

    end # Base

  end # Agent
end # Vpim

