=begin
  Copyright (C) 2008 Sam Roberts

  This library is free software; you can redistribute it and/or modify it
  under the same terms as the ruby language itself, see the file COPYING for
  details.
=end

require "cgi"
require "uri"

require "vpim/repo"

module Vpim
  module Agent
    # On failure, raise this with an error message. text/plain for now,
    # text/html later. Will convert to a 404 and a message.
    class NotFound < Exception
    end

    class Path
      def self.split_path(path)
        begin
          path = path.to_ary
        rescue NameError
          path = path.split("/")
        end
        path.map{|w| CGI.unescape(w)}
      end

      def initialize(uri, base = "")
        @uri  = URI.parse(uri.to_s)
        #pp [uri, base, @uri]
       if @uri.path.size == 0
         @uri.path = "/"
       end
        @path = Path.split_path(@uri.path)
        @base = base.to_str
        @mark = 0

        @base.split.size.times{ shift }
      end

      def to_path
        self
      end

      def shift
        @path[@mark += 1]
      end

      def append(name, scheme = nil)
        uri = @uri.dup
        uri.path += "/" + CGI.escape(name)
        if scheme
          uri.scheme = scheme
        end
        uri
      end

#     def prefix
#       @path[0, @mark].map{|p| CGI.escape(p)}.join("/") #+ "/"
#     end

    end

    module Form
      # FIXME - are these right?
      ICS   = "text/calendar"
      VCF   = "text/vcard"
      ATOM  = "text/xml+atom"
      PLAIN = "text/plain"
      HTML  = "text/html"

      # TODO items needs to include protocol and description (calendars as webcal)
      def self.html_list(path, description, items)
        return <<__
<html><body>
#{description}
<ul>
  #{
    items.map do |name,description,scheme|
      "<li><a href=\"#{path.append(name,scheme)}\">#{description || name}</a></li>\n"
    end
  }
</ul>
</body></html>
__
      end
    end

    # Return calendar information based on RESTful (lovein the jargon...)
    # paths. Input is a Vpim::Repo.
    #
    #   .../coding/month/atom
    #   .../coding/month/rss
    #   .../coding/events/month/ics              <- next month?
    #   .../coding/events/month/2008-04/ics      <- a specified month?
    #   .../coding/week/atom
    #   .../year/rss
    class Calendars
      def initialize(repo)
        @repo = repo
      end

      class Calendar
        def initialize(cal)
          @cal = cal
        end

        def get(path)
          form = path.shift

          case form
          when nil
            return Form.html_list(path, "Calendar #{@cal.name.inspect}:",
                                  [
                                    ["calendar", "download"],
                                    ["calendar", "subscription", "webcal"]
                                  ]
                   ), Form::HTML
          when "calendar"
            return @cal.encode, Form::ICS
#  TODO calendar as vCard? maybe one card per event?
#  TODO calendar as rss feed?
          else
            raise NotFound, "Calendar #{@cal.name} cannot convert to form #{form}"
          end
        end
      end

      def calendar(name)
        if cal = @repo.find{|c| c.name == name}
          return Calendar.new(cal)
        else
          raise NotFound, "Calendar #{name.inspect} does not exist"
        end
      end

      # Get object at this path. Return value is a tuple of data and mime content type.
      def get(path)
        case name = path.to_path.shift
        when nil
          return Form::html_list(path, "Calendars:", @repo.map{|c| c.name}), Form::HTML
        else
          calendar(name).get(path)
        end
      end
    end
  end
end

